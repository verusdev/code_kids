import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Виды ежедневных заданий.
enum DailyQuestKind { levels, stars, perfect, python }

/// Задание дня: что нужно сделать сегодня.
class DailyQuest {
  const DailyQuest({
    required this.kind,
    required this.target,
    required this.title,
    required this.emoji,
  });

  final DailyQuestKind kind;
  final int target;
  final String title;
  final String emoji;
}

/// Список заданий: каждый день выбирается одно (по номеру дня).
const List<DailyQuest> kDailyQuests = [
  DailyQuest(
    kind: DailyQuestKind.levels,
    target: 3,
    title: 'Пройди 3 уровня',
    emoji: '🎯',
  ),
  DailyQuest(
    kind: DailyQuestKind.stars,
    target: 5,
    title: 'Собери 5 звёзд',
    emoji: '⭐',
  ),
  DailyQuest(
    kind: DailyQuestKind.perfect,
    target: 1,
    title: 'Получи 3 звезды на уровне',
    emoji: '🌈',
  ),
  DailyQuest(
    kind: DailyQuestKind.python,
    target: 1,
    title: 'Реши урок Python',
    emoji: '🐍',
  ),
];

/// Считает ежедневную активность: **серию** дней подряд и выполнение
/// **задания дня**. Данные хранятся в SharedPreferences.
class DailyService extends ChangeNotifier {
  DailyService._();

  static final DailyService instance = DailyService._();

  static const String _storageKey = 'code_kids_daily_v1';

  /// Поставщик текущего времени — в тестах его можно подменить.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  String _today = '';
  String? _lastActive;
  int _streak = 0;
  int _bestStreak = 0;
  int _todayLevels = 0;
  int _todayStars = 0;
  int _todayPerfect = 0;
  int _todayPython = 0;
  int _questsCompleted = 0;
  String? _questDoneDay;

  /// Серия: сколько дней подряд ребёнок занимался.
  int get streak => _streak;

  /// Лучшая серия за всё время.
  int get bestStreak => _bestStreak;

  /// Сколько всего заданий дня выполнено.
  int get questsCompleted => _questsCompleted;

  /// Играл ли ребёнок уже сегодня.
  bool get playedToday => _lastActive == dateKey(clock());

  int get todayLevels => _todayLevels;
  int get todayStars => _todayStars;

  /// Ключ даты вида `2026-10-13`.
  static String dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Задание на сегодня.
  DailyQuest get quest {
    final day = clock();
    final dayNumber = day.difference(DateTime(2026, 1, 1)).inDays;
    final index = dayNumber.abs() % kDailyQuests.length;
    return kDailyQuests[index];
  }

  /// Сколько уже сделано по сегодняшнему заданию.
  int get questProgress => switch (quest.kind) {
        DailyQuestKind.levels => _todayLevels,
        DailyQuestKind.stars => _todayStars,
        DailyQuestKind.perfect => _todayPerfect,
        DailyQuestKind.python => _todayPython,
      };

  int get questTarget => quest.target;

  bool get questDone => questProgress >= questTarget;

  /// Сбросить дневные счётчики, если наступил новый день.
  /// Возвращает `true`, если день сменился.
  bool refresh() {
    final today = dateKey(clock());
    if (_today == today) return false;
    _today = today;
    _todayLevels = 0;
    _todayStars = 0;
    _todayPerfect = 0;
    _todayPython = 0;
    notifyListeners();
    _persist();
    return true;
  }

  /// Отметить пройденный уровень (или урок). Обновляет серию и задание дня.
  void recordLevel({required String gameId, required int stars}) {
    final today = dateKey(clock());
    if (_today != today) {
      _today = today;
      _todayLevels = 0;
      _todayStars = 0;
      _todayPerfect = 0;
      _todayPython = 0;
    }

    final wasDone = questDone;

    _todayLevels += 1;
    _todayStars += stars;
    if (stars >= 3) _todayPerfect += 1;
    if (gameId == 'python') _todayPython += 1;

    if (!wasDone && questDone) _questsCompleted += 1;

    if (_lastActive != today) {
      final yesterday = dateKey(clock().subtract(const Duration(days: 1)));
      _streak = (_lastActive == yesterday) ? _streak + 1 : 1;
      _lastActive = today;
      if (_streak > _bestStreak) _bestStreak = _streak;
    }

    _persist();
    notifyListeners();
  }

  /// Возвращает задание, если оно только что выполнено и ещё не праздновалось.
  DailyQuest? takeNewlyCompletedQuest() {
    final today = dateKey(clock());
    if (!questDone || _questDoneDay == today) return null;
    _questDoneDay = today;
    _persist();
    return quest;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _today = (map['today'] as String?) ?? '';
        _lastActive = map['lastActive'] as String?;
        _streak = (map['streak'] as num?)?.toInt() ?? 0;
        _bestStreak = (map['best'] as num?)?.toInt() ?? 0;
        _todayLevels = (map['levels'] as num?)?.toInt() ?? 0;
        _todayStars = (map['stars'] as num?)?.toInt() ?? 0;
        _todayPerfect = (map['perfect'] as num?)?.toInt() ?? 0;
        _todayPython = (map['python'] as num?)?.toInt() ?? 0;
        _questsCompleted = (map['quests'] as num?)?.toInt() ?? 0;
        _questDoneDay = map['questDay'] as String?;
      }
    } catch (_) {
      // Повреждённые данные — начинаем заново.
    }
    refresh();
  }

  @visibleForTesting
  Future<void> reset() async {
    _today = '';
    _lastActive = null;
    _streak = 0;
    _bestStreak = 0;
    _todayLevels = 0;
    _todayStars = 0;
    _todayPerfect = 0;
    _todayPython = 0;
    _questsCompleted = 0;
    _questDoneDay = null;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'today': _today,
          'lastActive': _lastActive,
          'streak': _streak,
          'best': _bestStreak,
          'levels': _todayLevels,
          'stars': _todayStars,
          'perfect': _todayPerfect,
          'python': _todayPython,
          'quests': _questsCompleted,
          'questDay': _questDoneDay,
        }),
      );
    } catch (_) {
      // Игнорируем ошибки записи.
    }
  }
}
