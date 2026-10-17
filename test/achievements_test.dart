import 'package:code_kids/achievements/achievements.dart';
import 'package:code_kids/models/achievement.dart';
import 'package:code_kids/screens/achievements_screen.dart';
import 'package:code_kids/services/achievements_service.dart';
import 'package:code_kids/services/daily_service.dart';
import 'package:code_kids/services/mascot_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Achievement _byId(String id) => kAchievements.firstWhere((a) => a.id == id);

void main() {
  group('условия достижений', () {
    test('на пустом прогрессе медалей нет', () {
      const snap = ProgressSnapshot({});
      expect(kAchievements.where((a) => a.isUnlocked(snap)), isEmpty);
    });

    test('первый пройденный уровень даёт «Первый шаг» и «Три из трёх»', () {
      const snap = ProgressSnapshot({
        'maze': [3],
      });
      expect(_byId('first_step').isUnlocked(snap), isTrue);
      expect(_byId('three_stars').isUnlocked(snap), isTrue);
      expect(_byId('star_10').isUnlocked(snap), isFalse);
      expect(_byId('robot').isUnlocked(snap), isFalse);
    });

    test('звёзды считаются по всем играм', () {
      final snap = ProgressSnapshot({
        'maze': List.filled(10, 3),
        'python': List.filled(5, 3),
      });
      expect(snap.allStars, 45);
      expect(snap.allPassed, 15);
      expect(snap.allPerfect, 15);
      expect(_byId('star_30').isUnlocked(snap), isTrue);
      expect(_byId('star_60').isUnlocked(snap), isFalse);
      expect(_byId('pythonist').isUnlocked(snap), isTrue);
      expect(_byId('robot').isUnlocked(snap), isTrue);
    });

    test('«Любознательный» и «Везде побывал» зависят от числа игр', () {
      final three = {for (final id in kAllGameIds.take(3)) id: const [1]};
      expect(_byId('explorer').isUnlocked(ProgressSnapshot(three)), isFalse);
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(three)), isFalse);

      final five = {for (final id in kAllGameIds.take(5)) id: const [1]};
      expect(_byId('explorer').isUnlocked(ProgressSnapshot(five)), isTrue);
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(five)), isFalse);

      final all = {for (final id in kAllGameIds) id: const [1]};
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(all)), isTrue);
    });

    test('идентификаторы и тексты медалей заполнены и уникальны', () {
      final ids = kAchievements.map((a) => a.id).toSet();
      expect(ids.length, kAchievements.length);
      for (final a in kAchievements) {
        expect(a.title.trim(), isNotEmpty, reason: a.id);
        expect(a.description.trim(), isNotEmpty, reason: a.id);
        expect(a.emoji.trim(), isNotEmpty, reason: a.id);
      }
    });
  });

  group('экран достижений', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.reset();
    });

    testWidgets('показывает заголовок, счётчик и медали', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('🏅 Достижения'), findsOneWidget);
      expect(find.text('Открыто медалей: 0 из ${kAchievements.length}'),
          findsOneWidget);
      expect(find.text('Первый шаг'), findsOneWidget);
      expect(find.text('Питонист'), findsOneWidget);
      // На пустом прогрессе медали закрыты — показываем замки.
      expect(find.text('🔒'), findsWidgets);
    });
  });

  group('вручение медалей', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AchievementsService.instance.reset();
    });

    test('takeNewlyUnlocked выдаёт новую медаль ровно один раз', () async {
      const snap = ProgressSnapshot({
        'maze': [3],
      });
      final first = AchievementsService.instance.takeNewlyUnlocked(snap);
      expect(first.map((a) => a.id), contains('first_step'));
      final second = AchievementsService.instance.takeNewlyUnlocked(snap);
      expect(second, isEmpty);
    });
  });

  group('условия медалей за наряд и наклейки', () {
    test('«Первый наряд» открывается за первую покупку в магазине', () {
      expect(_byId('first_outfit').isUnlocked(const ProgressSnapshot({})),
          isFalse);
      expect(
        _byId('first_outfit')
            .isUnlocked(const ProgressSnapshot({}, accessoriesOwnedCount: 1)),
        isTrue,
      );
    });

    test('«Коллекционер наклеек» открывается ровно на 10 наклейках', () {
      expect(
        _byId('sticker_collector')
            .isUnlocked(const ProgressSnapshot({}, stickerUnlockedCount: 9)),
        isFalse,
      );
      expect(
        _byId('sticker_collector')
            .isUnlocked(const ProgressSnapshot({}, stickerUnlockedCount: 10)),
        isTrue,
      );
    });

    test('copyWith меняет только указанные поля', () {
      const base = ProgressSnapshot({
        'maze': [3],
      }, streak: 2, questsCompleted: 1);
      final copy = base.copyWith(accessoriesOwnedCount: 3, stickerUnlockedCount: 4);

      expect(copy.stars, base.stars);
      expect(copy.streak, 2);
      expect(copy.questsCompleted, 1);
      expect(copy.accessoriesOwnedCount, 3);
      expect(copy.stickerUnlockedCount, 4);
      expect(copy.achievementsUnlocked, 0);
    });
  });

  group('currentSnapshot — связка сервисов', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.reset();
      await MascotService.instance.reset();
      await DailyService.instance.reset();
    });

    test('покупка наряда попадает в снимок и открывает «Первый наряд»',
        () async {
      for (var i = 0; i < 6; i++) {
        await ProgressService.instance.record('maze', i, 3, 50);
      }

      expect(_byId('first_outfit').isUnlocked(currentSnapshot()), isFalse);

      await MascotService.instance.buy(accessoryById('hat_cap')!);

      final snap = currentSnapshot();
      expect(snap.accessoriesOwnedCount, 1);
      expect(_byId('first_outfit').isUnlocked(snap), isTrue);
      // Число открытых медалей пересчитывается на «свежем» снимке.
      expect(snap.achievementsUnlocked, greaterThan(0));
    });
  });
}
