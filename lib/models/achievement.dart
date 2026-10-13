/// Модель достижения («медали») — чистая логика без зависимостей от Flutter,
/// чтобы её было легко проверять тестами.
library;

/// Снимок прогресса: `gameId -> список звёзд по уровням`.
class ProgressSnapshot {
  const ProgressSnapshot(
    this.stars, {
    this.streak = 0,
    this.questsCompleted = 0,
  });

  /// Звёзды по играм: `{ 'maze': [3, 2, 0, ...], 'python': [...] }`.
  final Map<String, List<int>> stars;

  /// Текущая серия дней подряд (для медалей за постоянство).
  final int streak;

  /// Сколько всего выполнено ежедневных заданий.
  final int questsCompleted;

  static const List<int> _none = [];

  List<int> _list(String gameId) => stars[gameId] ?? _none;

  /// Сумма звёзд по игре.
  int total(String gameId) =>
      _list(gameId).fold<int>(0, (sum, v) => sum + v);

  /// Сколько уровней игры пройдено (хотя бы 1 звезда).
  int passed(String gameId) => _list(gameId).where((v) => v > 0).length;

  /// Сколько уровней игры пройдено на 3 звезды.
  int perfect(String gameId) => _list(gameId).where((v) => v >= 3).length;

  /// Всего звёзд по всем играм.
  int get allStars =>
      stars.values.fold<int>(0, (sum, l) => sum + l.fold<int>(0, (a, b) => a + b));

  /// Всего пройденных уровней по всем играм.
  int get allPassed =>
      stars.values.fold<int>(0, (sum, l) => sum + l.where((v) => v > 0).length);

  /// Всего уровней с тремя звёздами по всем играм.
  int get allPerfect =>
      stars.values.fold<int>(0, (sum, l) => sum + l.where((v) => v >= 3).length);

  /// Сколько игр из списка ребёнок хотя бы начал (есть звезда).
  int started(Iterable<String> gameIds) =>
      gameIds.where((id) => total(id) > 0).length;
}

/// Одно достижение: условие проверяется по снимку прогресса.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.test,
  });

  final String id;
  final String title;

  /// Как получить медаль (показывается ребёнку).
  final String description;

  final String emoji;

  /// Условие получения.
  final bool Function(ProgressSnapshot snapshot) test;

  bool isUnlocked(ProgressSnapshot snapshot) => test(snapshot);
}
