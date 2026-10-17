/// Описание одного уровня игры «Ханойская башня».
///
/// [disks] — число дисков, [pegs] — число стержней (обычно 3),
/// [moveLimit] — предел ходов (0 = без предела). Минимум ходов для классической
/// башни с [disks] дисками и 3 стержнями равен 2^disks − 1.
class HanoiLevel {
  const HanoiLevel({
    required this.disks,
    this.pegs = 3,
    this.moveLimit = 0,
    required this.hint,
    required this.explanation,
  });

  final int disks;
  final int pegs;
  final int moveLimit;
  final String hint;
  final String explanation;

  /// Минимально возможное число ходов (для 3 стержней).
  int get optimalMoves => (1 << disks) - 1;
}

/// Пятнадцать уровней от простого к сложному.
const List<HanoiLevel> hanoiLevels = [
  HanoiLevel(
    disks: 2,
    hint: 'Перенеси оба диска на третий стержень.',
    explanation: 'Маленький диск кладём поверх большого — наоборот нельзя.',
  ),
  HanoiLevel(
    disks: 3,
    hint: 'Сначала освободи место для большого диска.',
    explanation: 'Чтобы перенести большой диск, сначала убери маленькие.',
  ),
  HanoiLevel(
    disks: 3,
    moveLimit: 8,
    hint: 'Постарайся уложиться в 8 ходов.',
    explanation: 'Оптимально — 7 ходов. План важнее скорости.',
  ),
  HanoiLevel(
    disks: 4,
    hint: 'Планируй каждый ход наперёд.',
    explanation: 'С 4 дисками минимум — 15 ходов. Не спеши!',
  ),
  HanoiLevel(
    disks: 4,
    moveLimit: 18,
    hint: 'Следи за числом ходов.',
    explanation: 'Держись близко к оптимуму — думай заранее.',
  ),
  HanoiLevel(
    disks: 5,
    hint: 'Разбей задачу на маленькие шаги.',
    explanation:
        'Сначала перенеси верхние 4 диска, потом большой, потом снова 4.',
  ),
  HanoiLevel(
    disks: 5,
    moveLimit: 35,
    hint: 'Уложись в 35 ходов.',
    explanation: 'Минимум — 31 ход. Терпение и внимание помогут.',
  ),
  HanoiLevel(
    disks: 6,
    hint: 'Действуй по плану, не торопись.',
    explanation: 'Минимум — 63 хода. Это марафон, а не спринт.',
  ),
  HanoiLevel(
    disks: 6,
    moveLimit: 70,
    hint: 'Старайся не ошибаться.',
    explanation: 'Каждый лишний ход отдаляет от победы.',
  ),
  HanoiLevel(
    disks: 7,
    hint: 'Такой уровень требует сосредоточенности.',
    explanation: 'Настоящий вызов! Минимум — 127 ходов.',
  ),
  HanoiLevel(
    disks: 7,
    moveLimit: 140,
    hint: 'Считай ходы и следи за планом.',
    explanation: 'Чем больше дисков, тем важнее стратегия.',
  ),
  HanoiLevel(
    disks: 8,
    hint: 'Настоящему мастеру не страшны 8 дисков.',
    explanation: 'Минимум — 255 ходов. Ты справишься!',
  ),
  HanoiLevel(
    disks: 8,
    moveLimit: 280,
    hint: 'Не сдавайся — просто думай.',
    explanation: 'Оптимум 255. Не сдавайся, если не вышло с первого раза.',
  ),
  HanoiLevel(
    disks: 9,
    hint: 'Почти финал — терпение!',
    explanation: 'Минимум — 511 ходов. Большая задача разбивается на шаги.',
  ),
  HanoiLevel(
    disks: 10,
    hint: 'Финальный уровень! Ты справишься!',
    explanation: 'Минимум — 1023 хода. Награда ждёт впереди!',
  ),
];
