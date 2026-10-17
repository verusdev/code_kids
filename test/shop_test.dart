import 'dart:convert';

import 'package:code_kids/screens/shop_screen.dart';
import 'package:code_kids/services/mascot_service.dart';
import 'package:code_kids/services/profile_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Profile _defaultProfile = Profile(id: 'default', name: 'Друг', emoji: '🧒');
const Profile _kidProfile = Profile(id: 'kid2', name: 'Маша', emoji: '👧');

MascotService get shop => MascotService.instance;

Accessory acc(String id) => accessoryById(id)!;

/// Подготовить [ProfileService] с заданным списком профилей.
Future<void> seedProfiles(
  List<Profile> list, {
  String currentId = 'default',
}) async {
  SharedPreferences.setMockInitialValues({
    'flutter.code_kids_profiles_v1': jsonEncode({
      'profiles': [for (final p in list) p.toJson()],
      'currentId': currentId,
    }),
  });
  await ProfileService.instance.load();
}

/// Записать ровно [n] звёзд в игру «maze».
Future<void> giveStars(int n) async {
  var left = n;
  var level = 0;
  while (left > 0) {
    final stars = left >= 3 ? 3 : left;
    await ProgressService.instance.record('maze', level, stars, 50);
    left -= stars;
    level++;
  }
}

/// Дать [MascotService] «догнать» асинхронный reload, запущенный сменой
/// профиля, и перечитать состояние явно.
Future<void> settleShop() async {
  await pumpEventQueue();
  await shop.load();
}

void main() {
  setUp(() async {
    await seedProfiles([_defaultProfile]);
    await ProgressService.instance.reset();
    await shop.reset();
  });

  group('MascotService — покупка', () {
    test('без звёзд купить нельзя', () async {
      expect(await shop.buy(acc('hat_cap')), isFalse);
      expect(shop.isOwned('hat_cap'), isFalse);
      expect(shop.spentStars, 0);
      expect(shop.stars, 0);
    });

    test('покупка списывает звёзды и отмечает наряд купленным', () async {
      await giveStars(30);
      expect(shop.stars, 30);

      expect(await shop.buy(acc('hat_cap')), isTrue);

      expect(shop.isOwned('hat_cap'), isTrue);
      expect(shop.ownedCount, 1);
      expect(shop.spentStars, 15);
      expect(shop.stars, 15, reason: '30 заработано − 15 потрачено');
    });

    test('повторная покупка того же наряда отклоняется', () async {
      await giveStars(30);
      expect(await shop.buy(acc('hat_cap')), isTrue);
      expect(await shop.buy(acc('hat_cap')), isFalse);
      expect(shop.spentStars, 15, reason: 'звёзды списались только один раз');
      expect(shop.ownedCount, 1);
    });

    test('не хватает звёзд на дорогой наряд — покупка отклоняется', () async {
      await giveStars(30);
      expect(await shop.buy(acc('hat_crown')), isFalse); // 👑 стоит 60
      expect(shop.isOwned('hat_crown'), isFalse);
      expect(shop.spentStars, 0);
    });
  });

  group('MascotService — наряд', () {
    test('надеть можно только купленный аксессуар', () async {
      await giveStars(30);
      await shop.equip(acc('hat_cap')); // ещё не куплен
      expect(shop.equippedId(AccessorySlot.hat), isNull);

      await shop.buy(acc('hat_cap'));
      await shop.equip(acc('hat_cap'));
      expect(shop.equippedId(AccessorySlot.hat), 'hat_cap');
      expect(shop.emojiForSlot(AccessorySlot.hat), '🧢');
      expect(shop.isEquipped(acc('hat_cap')), isTrue);
    });

    test('новый аксессуар в том же слоте заменяет прежний', () async {
      await giveStars(120);
      await shop.buy(acc('hat_cap')); // 15
      await shop.buy(acc('hat_helmet')); // 25

      await shop.equip(acc('hat_cap'));
      await shop.equip(acc('hat_helmet'));

      expect(shop.equippedId(AccessorySlot.hat), 'hat_helmet');
      expect(shop.equippedEmojis, ['🪖']);
    });

    test('снять аксессуар очищает слот', () async {
      await giveStars(30);
      await shop.buy(acc('hat_cap'));
      await shop.equip(acc('hat_cap'));

      await shop.unequip(AccessorySlot.hat);
      expect(shop.equippedId(AccessorySlot.hat), isNull);
      expect(shop.equippedEmojis, isEmpty);
    });

    test('toggle надевает и снимает', () async {
      await giveStars(30);
      await shop.buy(acc('face_bow'));

      await shop.toggle(acc('face_bow')); // надеть
      expect(shop.isEquipped(acc('face_bow')), isTrue);

      await shop.toggle(acc('face_bow')); // снять
      expect(shop.isEquipped(acc('face_bow')), isFalse);
      expect(shop.equippedId(AccessorySlot.face), isNull);
    });

    test('equippedEmojis идёт в порядке слотов: голова, мордочка, extra',
        () async {
      await giveStars(120);
      await shop.buy(acc('hat_cap')); // 🧢 / hat
      await shop.buy(acc('face_bow')); // 🎀 / face
      await shop.buy(acc('extra_scarf')); // 🧣 / extra

      // Надеваем в «обратном» порядке — список всё равно должен быть
      // упорядочен по слотам.
      await shop.equip(acc('extra_scarf'));
      await shop.equip(acc('face_bow'));
      await shop.equip(acc('hat_cap'));

      expect(shop.equippedEmojis, ['🧢', '🎀', '🧣']);
    });

    test('покупка и наряд сохраняются и перечитываются с диска', () async {
      await giveStars(60);
      await shop.buy(acc('hat_cap'));
      await shop.buy(acc('face_bow'));
      await shop.equip(acc('hat_cap'));

      await shop.reload();

      expect(shop.isOwned('hat_cap'), isTrue);
      expect(shop.isOwned('face_bow'), isTrue);
      expect(shop.equippedId(AccessorySlot.hat), 'hat_cap');
      expect(shop.spentStars, 25);
      expect(shop.stars, 35);
    });
  });

  group('MascotService — импорт', () {
    test('importData восстанавливает покупки, наряд и траты', () async {
      await shop.importData({
        'owned': ['hat_wizard', 'face_bow'],
        'equipped': {'hat': 'hat_wizard', 'face': 'face_bow'},
        'spent': 55,
      });

      expect(shop.ownedCount, 2);
      expect(shop.equippedId(AccessorySlot.hat), 'hat_wizard');
      expect(shop.equippedId(AccessorySlot.face), 'face_bow');
      expect(shop.spentStars, 55);
    });

    test('мусорные записи отбрасываются, наряд — только из купленного',
        () async {
      await shop.importData({
        'owned': ['hat_cap', 'не существует', 42, null],
        'equipped': {
          'hat': 'hat_cap',
          'face': 'face_bow', // не куплен — слот остаётся пустым
          'unknownslot': 'hat_cap', // нет такого слота
        },
        'spent': 'много', // не число
      });

      expect(shop.ownedCount, 1);
      expect(shop.isOwned('hat_cap'), isTrue);
      expect(shop.equippedId(AccessorySlot.hat), 'hat_cap');
      expect(shop.equippedId(AccessorySlot.face), isNull);
      expect(shop.spentStars, 0);
    });

    test('пустая карта очищает магазин', () async {
      await giveStars(30);
      await shop.buy(acc('hat_cap'));
      await shop.importData(const {});
      expect(shop.ownedCount, 0);
      expect(shop.equippedEmojis, isEmpty);
      expect(shop.spentStars, 0);
    });
  });

  group('магазин — per-profile', () {
    test('покупки и наряд хранятся отдельно для каждого профиля', () async {
      await seedProfiles([_defaultProfile, _kidProfile]);
      await giveStars(60);
      await shop.load();
      await shop.buy(acc('hat_cap'));
      await shop.equip(acc('hat_cap'));

      // Профиль Маши видит пустой магазин.
      await ProfileService.instance.switchTo('kid2');
      await settleShop();
      expect(shop.isOwned('hat_cap'), isFalse);
      expect(shop.equippedEmojis, isEmpty);

      // Маша покупает свой наряд — он не мешает «Другу».
      await giveStars(40);
      await shop.buy(acc('face_bow'));
      expect(shop.isOwned('face_bow'), isTrue);

      // Возвращаемся к «Другу» — его покупки и наряд на месте.
      await ProfileService.instance.switchTo('default');
      await settleShop();
      expect(shop.isOwned('hat_cap'), isTrue);
      expect(shop.isOwned('face_bow'), isFalse);
      expect(shop.equippedId(AccessorySlot.hat), 'hat_cap');
    });
  });

  group('экран магазина', () {
    Future<void> openShop(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('без звёзд все кнопки покупки отключены', (tester) async {
      await openShop(tester);

      expect(find.text('🛒 Наряды'), findsOneWidget);
      expect(find.text('У тебя: 0 ⭐'), findsOneWidget);
      expect(find.text('🧢'), findsOneWidget); // карточка «Спортсмен»
      // Ничего не куплено и звёзд нет — только мягкая подсказка.
      expect(find.text('Собери ещё звёздочки! ⭐'),
          findsNWidgets(kAccessories.length));
      expect(find.textContaining('Купить за'), findsNothing);
    });

    testWidgets('со звёздами доступные наряды можно купить, затем надеть',
        (tester) async {
      // Нажатие вызывает вибро/звук через платформенный канал. В тестах без
      // обработчика ответа не приходит и `await HapticFeedback...` «зависает»,
      // поэтому ставим заглушку ДО тапа.
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await giveStars(30);
      await shop.load();
      await openShop(tester);

      expect(find.text('У тебя: 30 ⭐'), findsOneWidget);
      expect(find.text('Купить за 15 ⭐'), findsOneWidget);
      // Дороже 30 звёзд — недоступны.
      expect(find.text('Собери ещё звёздочки! ⭐'), findsWidgets);

      await tester.tap(find.text('Купить за 15 ⭐'));
      await tester.pumpAndSettle();

      expect(shop.isOwned('hat_cap'), isTrue);
      expect(find.textContaining('Ура! Наряд «Спортсмен» открыт!'),
          findsOneWidget);
      expect(find.text('У тебя: 15 ⭐'), findsOneWidget);
      // После покупки кнопка превращается в «Надеть».
      expect(find.text('Надеть'), findsOneWidget);

      await tester.tap(find.text('Надеть'));
      await tester.pumpAndSettle();

      expect(shop.isEquipped(acc('hat_cap')), isTrue);
      expect(find.text('Снять'), findsOneWidget);
    });
  });
}
