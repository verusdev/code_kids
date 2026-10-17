import '../models/achievement.dart';

/// Коллекционная наклейка. Как и достижения, условия — **чистые функции**
/// от снимка прогресса, поэтому их легко проверять тестами.
class Sticker {
  const Sticker({
    required this.id,
    required this.emoji,
    required this.name,
    required this.hint,
    required this.condition,
  });

  /// Уникальный идентификатор наклейки.
  final String id;

  /// Эмодзи наклейки (крупно показывается в альбоме).
  final String emoji;

  /// Короткое название.
  final String name;

  /// Подсказка «как открыть» — показывается, пока наклейка закрыта.
  final String hint;

  /// Условие открытия по снимку прогресса.
  final bool Function(ProgressSnapshot snapshot) condition;

  /// Открыта ли наклейка на этом снимке прогресса.
  bool isUnlocked(ProgressSnapshot snapshot) => condition(snapshot);
}

/// Все наклейки альбома «📖 Наклейки» — от простых к самым редким.
const List<Sticker> kStickers = [
  // Звёзды.
  Sticker(
    id: 'star_10',
    emoji: '⭐',
    name: 'Десять звёзд',
    hint: 'Собери 10 звёзд',
    condition: _star10,
  ),
  Sticker(
    id: 'star_50',
    emoji: '🌟',
    name: 'Пятьдесят звёзд',
    hint: 'Собери 50 звёзд',
    condition: _star50,
  ),
  Sticker(
    id: 'star_150',
    emoji: '💫',
    name: 'Сто пятьдесят',
    hint: 'Собери 150 звёзд',
    condition: _star150,
  ),
  Sticker(
    id: 'star_300',
    emoji: '🌠',
    name: 'Триста звёзд',
    hint: 'Собери 300 звёзд',
    condition: _star300,
  ),

  // Уровни и «три звезды».
  Sticker(
    id: 'first_step',
    emoji: '🐣',
    name: 'Первые шаги',
    hint: 'Пройди любой уровень',
    condition: _firstStep,
  ),
  Sticker(
    id: 'perfect_5',
    emoji: '🌈',
    name: 'Радуга',
    hint: 'Получи 3 звезды на 5 уровнях',
    condition: _perfect5,
  ),
  Sticker(
    id: 'perfect_15',
    emoji: '🏆',
    name: 'Отличник',
    hint: 'Получи 3 звезды на 15 уровнях',
    condition: _perfect15,
  ),

  // Отдельные игры.
  Sticker(
    id: 'maze_5',
    emoji: '🤖',
    name: 'Робот-друг',
    hint: 'Пройди 5 уровней «Робот-Лабиринт»',
    condition: _maze5,
  ),
  Sticker(
    id: 'pixel_5',
    emoji: '🎨',
    name: 'Художник',
    hint: 'Пройди 5 уровней «Пиксель-арт»',
    condition: _pixel5,
  ),
  Sticker(
    id: 'blocks_5',
    emoji: '📦',
    name: 'Мастер блоков',
    hint: 'Пройди 5 уровней «Программируй блоками»',
    condition: _blocks5,
  ),
  Sticker(
    id: 'python_3',
    emoji: '🐍',
    name: 'Юный питонист',
    hint: 'Реши 3 урока Python',
    condition: _python3,
  ),
  Sticker(
    id: 'python_10',
    emoji: '🐲',
    name: 'Дракон Python',
    hint: 'Реши 10 уроков Python',
    condition: _python10,
  ),

  // Постоянство.
  Sticker(
    id: 'streak_3',
    emoji: '🔥',
    name: 'Три дня подряд',
    hint: 'Занимайся 3 дня подряд',
    condition: _streak3,
  ),
  Sticker(
    id: 'streak_7',
    emoji: '📅',
    name: 'Целая неделя',
    hint: 'Занимайся 7 дней подряд',
    condition: _streak7,
  ),

  // Разное.
  Sticker(
    id: 'medals_5',
    emoji: '🏅',
    name: 'Пять медалей',
    hint: 'Открой 5 медалей',
    condition: _medals5,
  ),
  Sticker(
    id: 'explorer',
    emoji: '🧭',
    name: 'Путешественник',
    hint: 'Начни играть в 5 разных игр',
    condition: _explorer,
  ),
];

/// Сколько наклеек открыто на этом снимке прогресса.
int unlockedStickerCount(ProgressSnapshot snapshot) =>
    kStickers.where((s) => s.isUnlocked(snapshot)).length;

// Условия вынесены в отдельные функции: так их удобно переиспользовать
// и держать список наклеек максимально декларативным.

bool _star10(ProgressSnapshot s) => s.allStars >= 10;
bool _star50(ProgressSnapshot s) => s.allStars >= 50;
bool _star150(ProgressSnapshot s) => s.allStars >= 150;
bool _star300(ProgressSnapshot s) => s.allStars >= 300;

bool _firstStep(ProgressSnapshot s) => s.allPassed >= 1;
bool _perfect5(ProgressSnapshot s) => s.allPerfect >= 5;
bool _perfect15(ProgressSnapshot s) => s.allPerfect >= 15;

bool _maze5(ProgressSnapshot s) => s.passed('maze') >= 5;
bool _pixel5(ProgressSnapshot s) => s.passed('pixel') >= 5;
bool _blocks5(ProgressSnapshot s) => s.passed('blocks') >= 5;
bool _python3(ProgressSnapshot s) => s.passed('python') >= 3;
bool _python10(ProgressSnapshot s) => s.passed('python') >= 10;

bool _streak3(ProgressSnapshot s) => s.streak >= 3;
bool _streak7(ProgressSnapshot s) => s.streak >= 7;

bool _medals5(ProgressSnapshot s) => s.achievementsUnlocked >= 5;

/// Сколько разных игр ребёнок уже начал (есть хотя бы одна звезда).
bool _explorer(ProgressSnapshot s) =>
    s.stars.keys.where((id) => s.total(id) > 0).length >= 5;
