import 'package:code_kids/services/daily_service.dart';
import 'package:code_kids/services/profile_service.dart';
import 'package:code_kids/widgets/daily_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final daily = DailyService.instance;

  /// Выполняет текущее задание дня подходящими действиями.
  void completeQuest() {
    final quest = daily.quest;
    for (var i = 0; i < quest.target; i++) {
      switch (quest.kind) {
        case DailyQuestKind.levels:
          daily.recordLevel(gameId: 'maze', stars: 1);
        case DailyQuestKind.stars:
          daily.recordLevel(gameId: 'maze', stars: 3);
        case DailyQuestKind.perfect:
          daily.recordLevel(gameId: 'maze', stars: 3);
        case DailyQuestKind.python:
          daily.recordLevel(gameId: 'python', stars: 3);
      }
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await daily.reset();
    daily.clock = DateTime.now;
  });

  tearDown(() {
    daily.clock = DateTime.now;
  });

  group('серия дней', () {
    test('новая серия начинается с 1 при первой активности', () {
      daily.clock = () => DateTime(2026, 10, 1, 12);
      daily.recordLevel(gameId: 'maze', stars: 3);
      expect(daily.streak, 1);
      expect(daily.bestStreak, 1);
      expect(daily.playedToday, isTrue);
    });

    test('играл вчера — серия растёт, пропуск дня — сбрасывается', () {
      daily.clock = () => DateTime(2026, 10, 1, 12);
      daily.recordLevel(gameId: 'maze', stars: 3);

      daily.clock = () => DateTime(2026, 10, 2, 9);
      daily.recordLevel(gameId: 'maze', stars: 2);
      expect(daily.streak, 2);

      daily.clock = () => DateTime(2026, 10, 3, 9);
      daily.recordLevel(gameId: 'maze', stars: 1);
      expect(daily.streak, 3);
      expect(daily.bestStreak, 3);

      // Пропустили день: 3 —> 5 октября.
      daily.clock = () => DateTime(2026, 10, 5, 9);
      daily.recordLevel(gameId: 'maze', stars: 3);
      expect(daily.streak, 1);
      expect(daily.bestStreak, 3);
    });

    test('несколько уровней в один день — одна серия, но растёт счётчик', () {
      daily.clock = () => DateTime(2026, 10, 1, 12);
      daily.recordLevel(gameId: 'maze', stars: 1);
      daily.recordLevel(gameId: 'pixel', stars: 1);
      daily.recordLevel(gameId: 'python', stars: 1);
      expect(daily.streak, 1);
      expect(daily.todayLevels, 3);
      expect(daily.todayStars, 3);
    });
  });

  group('задание дня', () {
    test('прогресс и выполнение определяются по действиям', () {
      daily.clock = () => DateTime(2026, 10, 13, 12);
      expect(daily.questDone, isFalse);

      completeQuest();

      expect(daily.questProgress >= daily.questTarget, isTrue);
      expect(daily.questDone, isTrue);
    });

    test('выполненное задание выдаётся ровно один раз в день', () {
      daily.clock = () => DateTime(2026, 10, 13, 12);
      completeQuest();

      expect(daily.questsCompleted, 1);
      expect(daily.takeNewlyCompletedQuest(), isNotNull);
      expect(daily.takeNewlyCompletedQuest(), isNull);
    });

    test('новый день сбрасывает дневной прогресс', () {
      daily.clock = () => DateTime(2026, 10, 13, 12);
      completeQuest();
      expect(daily.questDone, isTrue);

      daily.clock = () => DateTime(2026, 10, 14, 8);
      expect(daily.refresh(), isTrue);
      expect(daily.todayLevels, 0);
      expect(daily.questDone, isFalse);
    });
  });

  group('форма слова «день»', () {
    test('1 день, 2 дня, 5 дней, 11 дней, 21 день', () {
      expect(DailyCard.daysWord(1), 'день');
      expect(DailyCard.daysWord(2), 'дня');
      expect(DailyCard.daysWord(5), 'дней');
      expect(DailyCard.daysWord(11), 'дней');
      expect(DailyCard.daysWord(21), 'день');
      expect(DailyCard.daysWord(22), 'дня');
      expect(DailyCard.daysWord(13), 'дней');
    });
  });

  group('сохранение', () {
    // Данные ежедневной активности хранятся отдельно для каждого профиля:
    // ключ `<base>::<profileId>`, а не старый глобальный ключ.
    final profileKey =
        ProfileService.instance.storageKey('code_kids_daily_v1');

    test('серия и счётчики дня сохраняются после перезагрузки', () async {
      daily.clock = () => DateTime(2026, 10, 13, 12);
      daily.recordLevel(gameId: 'maze', stars: 3);
      daily.recordLevel(gameId: 'maze', stars: 2);
      expect(daily.streak, 1);
      expect(daily.todayLevels, 2);

      // Сохраняем «снимок» хранилища, чистим память и восстанавливаем его.
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(profileKey);
      expect(saved, isNotNull);
      await daily.reset();
      expect(daily.streak, 0);
      await prefs.setString(profileKey, saved!);
      await daily.load();

      expect(daily.streak, 1);
      expect(daily.todayLevels, 2);
      expect(daily.todayStars, 5);
      expect(daily.playedToday, isTrue);
    });

    test('старый глобальный ключ мигрирует в профиль по умолчанию', () async {
      // Чистое хранилище: профильного ключа ещё нет, есть только старый.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const legacy = '{"today":"2026-10-13","lastActive":"2026-10-13",'
          '"streak":4,"best":9,"levels":2,"stars":5,"perfect":1,'
          '"python":0,"quests":1,"questDay":"2026-10-13"}';
      await prefs.setString('code_kids_daily_v1', legacy);

      await daily.load();

      // Старые «глобальные» данные подхватились профилем по умолчанию.
      expect(daily.streak, 4);
      expect(daily.bestStreak, 9);
      final defaultKey = ProfileService.instance.storageKeyFor(
        'code_kids_daily_v1',
        ProfileService.defaultProfileId,
      );
      expect(prefs.getString(defaultKey), isNotNull);
      // Старое значение не удаляем — миграция безопасна и повторяема.
      expect(prefs.getString('code_kids_daily_v1'), isNotNull);
    });
  });
}
