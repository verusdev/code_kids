import 'dart:convert';

import 'package:code_kids/screens/profiles_screen.dart';
import 'package:code_kids/services/profile_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Небольшая пауза: идентификаторы профилей строятся из «микросекунд»
/// `DateTime.now()`, а на Windows часы обновляются крупными шагами (~15 мс).
/// Пауза гарантирует разные id у последовательно созданных профилей.
Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 20));

ProfileService get profiles => ProfileService.instance;

const Profile _defaultProfile = Profile(id: 'default', name: 'Друг', emoji: '🧒');

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
  await profiles.load();
}

void main() {
  // ВАЖНО: этот тест должен идти первым — он проверяет самое первое
  // наполнение сервиса, когда в памяти ещё нет ни одного профиля.
  test('при первом запуске (пустое хранилище) создаётся профиль «default»',
      () async {
    SharedPreferences.setMockInitialValues({});
    await profiles.load();

    expect(profiles.profiles, hasLength(1));
    expect(profiles.currentId, ProfileService.defaultProfileId);
    expect(profiles.current.name, 'Друг');
    expect(profiles.current.emoji, '🧒');

    // Профиль сразу сохранён на диск.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('code_kids_profiles_v1'), isNotNull);
  });

  group('ProfileService — storageKey', () {
    test('ключ зависит от текущего профиля', () async {
      await seedProfiles([_defaultProfile], currentId: 'default');
      expect(profiles.storageKey('code_kids_progress_v1'),
          'code_kids_progress_v1::default');
      expect(profiles.storageKeyFor('code_kids_progress_v1', 'p42'),
          'code_kids_progress_v1::p42');
    });
  });

  group('ProfileService — add', () {
    test('добавляет профиль, чистит имя и подставляет аватар', () async {
      await seedProfiles([_defaultProfile]);

      final added = profiles.add('   Маша   ', '👧');
      expect(added.name, 'Маша');
      expect(added.emoji, '👧');
      expect(added.id, isNotEmpty);
      expect(profiles.profiles, hasLength(2));

      // Пустое имя → «Друг», пустой аватар → 🧒.
      final second = profiles.add('   ', '');
      expect(second.name, 'Друг');
      expect(second.emoji, '🧒');
    });

    test('у последовательных профилей разные идентификаторы', () async {
      await seedProfiles([_defaultProfile]);
      final a = profiles.add('Маша', '👧');
      await _tick();
      final b = profiles.add('Петя', '👦');
      expect(a.id, isNot(b.id));
    });
  });

  group('ProfileService — rename', () {
    test('меняет имя и аватар', () async {
      await seedProfiles([_defaultProfile]);
      await profiles.rename('default', name: 'Ника', emoji: '🦊');
      expect(profiles.current.name, 'Ника');
      expect(profiles.current.emoji, '🦊');
    });

    test('пустое имя не сбрасывает профиль в пустоту, пустой аватар сохраняется',
        () async {
      await seedProfiles(
        [const Profile(id: 'p1', name: 'Маша', emoji: '👧')],
        currentId: 'p1',
      );
      await profiles.rename('p1', name: '   ', emoji: '');
      expect(profiles.profiles.single.name, 'Друг');
      expect(profiles.profiles.single.emoji, '👧');
    });

    test('несуществующий профиль игнорируется', () async {
      await seedProfiles([_defaultProfile]);
      await profiles.rename('nope', name: 'X');
      expect(profiles.profiles.single.name, 'Друг');
    });
  });

  group('ProfileService — remove', () {
    test('нельзя удалить единственный профиль', () async {
      await seedProfiles([_defaultProfile]);
      expect(await profiles.remove('default'), isFalse);
      expect(profiles.profiles, hasLength(1));
    });

    test('удаление несуществующего возвращает false', () async {
      await seedProfiles([
        _defaultProfile,
        const Profile(id: 'p2', name: 'Маша', emoji: '👧'),
      ]);
      expect(await profiles.remove('nope'), isFalse);
      expect(profiles.profiles, hasLength(2));
    });

    test('удаление текущего переключает на первый оставшийся', () async {
      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'p2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'p2',
      );

      expect(await profiles.remove('p2'), isTrue);
      expect(profiles.currentId, 'default');
      expect(profiles.profiles.single.id, 'default');
    });

    test('удаление не текущего не меняет текущий', () async {
      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'p2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'default',
      );

      expect(await profiles.remove('p2'), isTrue);
      expect(profiles.currentId, 'default');
    });
  });

  group('ProfileService — персистентность', () {
    test('список профилей сохраняется и перечитывается', () async {
      await seedProfiles([_defaultProfile]);
      final added = profiles.add('Маша', '👧');
      await _tick();
      // switchTo дожидается записи на диск.
      await profiles.switchTo(added.id);

      final prefs = await SharedPreferences.getInstance();
      final decoded =
          jsonDecode(prefs.getString('code_kids_profiles_v1')!)
              as Map<String, dynamic>;
      expect((decoded['profiles'] as List), hasLength(2));
      expect(decoded['currentId'], added.id);

      // Перечитываем с диска — данные не потерялись.
      await profiles.load();
      expect(profiles.profiles, hasLength(2));
      expect(profiles.currentId, added.id);
      expect(profiles.current.name, 'Маша');
    });

    test('пустой список профилей заменяется профилем по умолчанию', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.code_kids_profiles_v1':
            jsonEncode({'profiles': <Object>[], 'currentId': ''}),
      });
      await profiles.load();

      expect(profiles.profiles, hasLength(1));
      expect(profiles.currentId, ProfileService.defaultProfileId);
    });

    test('повреждённый JSON не роняет сервис', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.code_kids_profiles_v1': '{ это не json',
      });

      // Не должно бросать исключение.
      await profiles.load();

      // Текущий профиль всегда валиден, даже если данные повреждены.
      expect(profiles.profiles, isNotEmpty);
      expect(profiles.current.name, isNotEmpty);
    });
  });

  group('профили в прогрессе', () {
    setUp(() async {
      await ProgressService.instance.reset();
    });

    test('старый глобальный прогресс мигрирует в профиль по умолчанию',
        () async {
      SharedPreferences.setMockInitialValues({
        'flutter.code_kids_profiles_v1': jsonEncode({
          'profiles': [_defaultProfile.toJson()],
          'currentId': 'default',
        }),
        'flutter.code_kids_progress_v1': '{"maze":[3,2,0]}',
      });
      await profiles.load();
      await ProgressService.instance.load();

      expect(ProgressService.instance.starsFor('maze', 0), 3);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('code_kids_progress_v1::default'), isNotNull);
      // Старый ключ не удаляется.
      expect(prefs.getString('code_kids_progress_v1'), isNotNull);
    });

    test('у каждого профиля свои звёзды, switchTo + reload переключает данные',
        () async {
      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'kid2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'default',
      );

      await ProgressService.instance.reload();
      await ProgressService.instance.record('maze', 0, 3, 5);
      expect(ProgressService.instance.totalStars('maze'), 3);

      await profiles.switchTo('kid2');
      await ProgressService.instance.reload();
      expect(ProgressService.instance.totalStars('maze'), 0,
          reason: 'у второго профиля прогресс пуст');

      await ProgressService.instance.record('maze', 0, 1, 5);
      expect(ProgressService.instance.totalStars('maze'), 1);

      await profiles.switchTo('default');
      await ProgressService.instance.reload();
      expect(ProgressService.instance.totalStars('maze'), 3,
          reason: 'вернулись — звёзды первого профиля на месте');
    });

    test('totalStarsForProfile читает звёзды любого профиля', () async {
      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'kid2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'default',
      );

      await ProgressService.instance.reload();
      await ProgressService.instance.record('maze', 0, 3, 5);
      await profiles.switchTo('kid2');
      await ProgressService.instance.reload();
      await ProgressService.instance.record('pixel', 0, 2, 5);

      expect(await ProgressService.instance.totalStarsForProfile('default'), 3);
      expect(await ProgressService.instance.totalStarsForProfile('kid2'), 2);
      expect(await ProgressService.instance.totalStarsForProfile('nope'), 0);
    });
  });

  group('экран выбора профиля', () {
    Future<void> openProfiles(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilesScreen()),
                  ),
                  child: const Text('ОТКРЫТЬ'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ОТКРЫТЬ'));
      await tester.pumpAndSettle();
    }

    testWidgets('показывает карточки, звёзды и пометку текущего профиля',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'kid2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'kid2',
      );
      await ProgressService.instance.reload();
      await ProgressService.instance.record('maze', 0, 3, 5);

      await openProfiles(tester);

      expect(find.text('Кто играет?'), findsOneWidget);
      expect(find.text('Друг'), findsOneWidget);
      expect(find.text('Маша'), findsOneWidget);
      expect(find.text('⭐ 3'), findsOneWidget); // звёзды Маши
      expect(find.text('⭐ 0'), findsOneWidget); // у «Друга» пусто
      expect(find.text('Сейчас играет'), findsOneWidget);
    });

    testWidgets('добавляет новый профиль через диалог', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedProfiles([_defaultProfile]);
      await openProfiles(tester);

      await tester.tap(find.text('➕ Добавить профиль'));
      await tester.pumpAndSettle();
      expect(find.text('Новый профиль'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Петя');
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      expect(find.text('Петя'), findsOneWidget);
      expect(profiles.profiles, hasLength(2));
    });

    testWidgets('переключение профиля меняет текущий и закрывает экран',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedProfiles(
        [
          _defaultProfile,
          const Profile(id: 'kid2', name: 'Маша', emoji: '👧'),
        ],
        currentId: 'kid2',
      );
      await openProfiles(tester);

      expect(profiles.currentId, 'kid2');

      // Тапаем по карточке «Друг» — это переключит текущий профиль.
      await tester.tap(find.text('Друг'));
      await tester.pumpAndSettle();

      expect(profiles.currentId, 'default');
      expect(find.text('ОТКРЫТЬ'), findsOneWidget, reason: 'экран закрылся');
    });

    testWidgets('единственный профиль удалить нельзя — показывается подсказка',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedProfiles([_defaultProfile]);
      await openProfiles(tester);

      await tester.tap(find.text('⚙️ Настроить'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('🗑️'));
      await tester.pumpAndSettle();

      expect(find.text('Нельзя удалить единственный профиль 🙂'), findsOneWidget);
      expect(profiles.profiles, hasLength(1));
    });
  });
}
