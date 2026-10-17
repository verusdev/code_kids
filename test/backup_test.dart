import 'dart:convert';

import 'package:code_kids/models/achievement.dart';
import 'package:code_kids/services/achievements_service.dart';
import 'package:code_kids/services/challenge_service.dart';
import 'package:code_kids/services/daily_service.dart';
import 'package:code_kids/services/profile_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Тесты экспорта/импорта прогресса — того самого механизма, который
/// использует экран «Родителям» (кнопки «Скопировать прогресс» /
/// «Вставить и восстановить»).
///
/// Бэкап — это JSON вида:
/// `{ "profile": {...}, "progress": {...}, "achievements": [...],
///    "daily": {...}, "challenge": `<int>` }`.
void main() {
  final progress = ProgressService.instance;
  final achievements = AchievementsService.instance;
  final daily = DailyService.instance;
  final challenge = ChallengeService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'flutter.code_kids_profiles_v1': jsonEncode({
        'profiles': [
          const Profile(id: 'default', name: 'Друг', emoji: '🧒').toJson(),
        ],
        'currentId': 'default',
      }),
    });
    await ProfileService.instance.load();
    await progress.reset();
    await achievements.reset();
    await daily.reset();
    await challenge.reset();
    daily.clock = () => DateTime(2026, 10, 13, 12);
  });

  tearDown(() {
    daily.clock = DateTime.now;
  });

  /// Собрать бэкап текущего состояния — как это делает экран «Родителям».
  String buildBackup() => jsonEncode({
        'profile': {'name': 'Друг', 'emoji': '🧒'},
        'progress': progress.exportData(),
        'achievements': achievements.exportData(),
        'daily': daily.exportData(),
        'challenge': challenge.exportData(),
      });

  /// Применить бэкап — повторяет логику `_paste` на экране «Родителям».
  Future<void> applyBackup(String text) async {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    await progress.importData(Map<String, dynamic>.from(decoded['progress']));
    await achievements.importData(
      (decoded['achievements'] as List).whereType<String>().toList(),
    );
    await daily.importData(Map<String, dynamic>.from(decoded['daily']));
    await challenge.importData((decoded['challenge'] as num).toInt());
  }

  group('экспорт → импорт', () {
    test('восстанавливает звёзды, медали, серию и рекорд', () async {
      await progress.record('maze', 0, 3, 45);
      await progress.record('maze', 1, 2, 45);
      await progress.record('pixel', 4, 3, 45);
      // Синхронный метод: вычитываем только что разблокированные медали.
      achievements.takeNewlyUnlocked(ProgressSnapshot(progress.snapshot));
      daily.recordLevel(gameId: 'maze', stars: 3);
      daily.recordLevel(gameId: 'maze', stars: 2);
      await challenge.record(42);

      final backup = buildBackup();
      final expectedStars = progress.snapshot;
      final expectedMedals = achievements.exportData();
      expect(expectedMedals, isNotEmpty);

      // Всё сбрасываем и «переезжаем» через бэкап.
      await progress.reset();
      await achievements.reset();
      await daily.reset();
      await challenge.reset();
      expect(progress.totalStars('maze'), 0);

      await applyBackup(backup);

      expect(progress.snapshot, expectedStars);
      expect(progress.starsFor('maze', 0), 3);
      expect(progress.starsFor('pixel', 4), 3);
      expect(achievements.exportData().toSet(), expectedMedals.toSet());
      expect(daily.streak, 1);
      expect(daily.todayLevels, 2);
      expect(daily.todayStars, 5);
      expect(challenge.bestSeconds, 42);
    });

    test('отработанный из хранилища бэкап переживает перечитывание с диска',
        () async {
      await progress.record('maze', 0, 3, 45);
      final backup = buildBackup();
      await progress.reset();
      await applyBackup(backup);

      // Имитируем перезапуск: перечитываем всё с диска.
      await progress.reload();
      await achievements.reload();
      await daily.reload();
      await challenge.reload();

      expect(progress.starsFor('maze', 0), 3);
    });
  });

  group('импорт мусора', () {
    test('прогресс: нечисловые и несписочные значения пропускаются', () async {
      await progress.importData({
        'maze': 'это не список',
        'pixel': [1, 2, 'мусор', 3],
        'stars': <Object>[],
      });

      // 'maze' отброшен целиком, у 'pixel' остались только числа.
      expect(progress.totalStars('maze'), 0);
      expect(progress.snapshot['pixel'], [1, 2, 3]);
      await progress.reload();
      expect(progress.snapshot['pixel'], [1, 2, 3]);
    });

    test('серия: некорректные типы приводятся к нулю', () async {
      await daily.importData({
        'streak': 'много',
        'best': 3.5,
        'levels': 'x',
        'lastActive': 555,
      });

      expect(daily.streak, 0);
      expect(daily.bestStreak, 3); // double приводится к int
      expect(daily.todayLevels, 0);
      expect(daily.playedToday, isFalse);
    });

    test('рекорд: отрицательное значение → «рекорда нет»', () async {
      await challenge.importData(-5);
      expect(challenge.bestSeconds, 0);

      await challenge.importData(0);
      expect(challenge.bestSeconds, 0);
    });

    test('медали: импортируются только строковые идентификаторы', () async {
      await achievements.importData(['first_step', 'три_звезды']);
      expect(achievements.isCelebrated('first_step'), isTrue);
      expect(achievements.isCelebrated('три_звезды'), isTrue);
      expect(achievements.isCelebrated('не_медаль'), isFalse);
    });

    test('пустой бэкап не роняет импорт', () async {
      await progress.importData(const {});
      await daily.importData(const {});
      await achievements.importData(const []);

      expect(progress.snapshot, isEmpty);
      expect(daily.streak, 0);
    });
  });
}
