import '../models/achievement.dart';
import '../models/game_models.dart';
import '../services/daily_service.dart';
import '../services/progress_service.dart';

/// Все игровые разделы (включая Python-курс) — для достижения «Везде побывал».
final List<String> kAllGameIds = [
  for (final g in kGames) g.id,
  for (final g in kSystemGames) g.id,
  'python',
];

/// Полный список медалей: от простых к самым сложным.
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_step',
    title: 'Первый шаг',
    description: 'Пройди любой уровень',
    emoji: '🐣',
    test: (s) => s.allPassed >= 1,
  ),
  Achievement(
    id: 'three_stars',
    title: 'Три из трёх',
    description: 'Получи 3 звезды на любом уровне',
    emoji: '🌈',
    test: (s) => s.allPerfect >= 1,
  ),
  Achievement(
    id: 'star_10',
    title: 'Звёздный дождь',
    description: 'Собери 10 звёзд',
    emoji: '⭐',
    test: (s) => s.allStars >= 10,
  ),
  Achievement(
    id: 'star_30',
    title: 'Коллекционер',
    description: 'Собери 30 звёзд',
    emoji: '🌟',
    test: (s) => s.allStars >= 30,
  ),
  Achievement(
    id: 'star_60',
    title: 'Звёздный мастер',
    description: 'Собери 60 звёзд',
    emoji: '💫',
    test: (s) => s.allStars >= 60,
  ),
  Achievement(
    id: 'star_100',
    title: 'Легенда звёзд',
    description: 'Собери 100 звёзд',
    emoji: '🏆',
    test: (s) => s.allStars >= 100,
  ),
  Achievement(
    id: 'explorer',
    title: 'Любознательный',
    description: 'Попробуй 5 разных игр',
    emoji: '🧭',
    test: (s) => s.started(kAllGameIds) >= 5,
  ),
  Achievement(
    id: 'master_all',
    title: 'Везде побывал',
    description: 'Начни играть во все игры',
    emoji: '🗺️',
    test: (s) => s.started(kAllGameIds) >= kAllGameIds.length,
  ),
  Achievement(
    id: 'robot',
    title: 'Робот-инженер',
    description: 'Пройди 5 уровней «Робот-Лабиринт»',
    emoji: '🤖',
    test: (s) => s.passed('maze') >= 5,
  ),
  Achievement(
    id: 'painter',
    title: 'Художник',
    description: 'Пройди 5 уровней «Пиксель-арт»',
    emoji: '🎨',
    test: (s) => s.passed('pixel') >= 5,
  ),
  Achievement(
    id: 'blocker',
    title: 'Мастер блоков',
    description: 'Пройди 5 уровней «Программируй блоками»',
    emoji: '📦',
    test: (s) => s.passed('blocks') >= 5,
  ),
  Achievement(
    id: 'pythonist',
    title: 'Питонист',
    description: 'Реши 5 уроков Python-курса',
    emoji: '🐍',
    test: (s) => s.passed('python') >= 5,
  ),
  Achievement(
    id: 'perfect_ten',
    title: 'Отличник',
    description: 'Получи 3 звезды на 10 уровнях',
    emoji: '👑',
    test: (s) => s.allPerfect >= 10,
  ),
  Achievement(
    id: 'quest_1',
    title: 'Задание дня',
    description: 'Выполни ежедневное задание',
    emoji: '🎁',
    test: (s) => s.questsCompleted >= 1,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Три дня подряд',
    description: 'Занимайся 3 дня подряд',
    emoji: '🔥',
    test: (s) => s.streak >= 3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Целая неделя',
    description: 'Занимайся 7 дней подряд',
    emoji: '🗓️',
    test: (s) => s.streak >= 7,
  ),
];

/// Актуальный снимок прогресса ребёнка.
ProgressSnapshot currentSnapshot() => ProgressSnapshot(
      ProgressService.instance.snapshot,
      streak: DailyService.instance.streak,
      questsCompleted: DailyService.instance.questsCompleted,
    );
