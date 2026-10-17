class MemoryCard {
  final int id; // уникальный идентификатор пары/карточки
  final String emoji; // эмодзи карточки

  const MemoryCard({required this.id, required this.emoji});
}

class MemoryLevel {
  final int pairs; // количество пар
  final int columns; // число колонок сетки
  final int rows; // число рядов сетки
  final List<String> emojiSet; // набор эмодзи для этого уровня (ровно pairs)
  final int idealMoves; // идеальное число ходов (открытие пары = 2 переворота)
  final int stars2Moves; // <= stars2Moves -> 2 звезды (неидеально, но близко)
  final int
  stars1Moves; // <= stars1Moves -> 1 звезда (иначе 0? но требуем 1-иначе)
  final String hint; // подсказка на русском
  final String explanation; // объяснение на русском

  const MemoryLevel({
    required this.pairs,
    required this.columns,
    required this.rows,
    required this.emojiSet,
    required this.idealMoves,
    required this.stars2Moves,
    required this.stars1Moves,
    required this.hint,
    required this.explanation,
  });
}

// Детерминированные уровни (15). Сетка чётная (pairs*2 карточек).
const List<MemoryLevel> memoryLevels = [
  MemoryLevel(
    pairs: 2,
    columns: 2,
    rows: 2,
    emojiSet: ['🐶', '🐱'],
    idealMoves: 2,
    stars2Moves: 3,
    stars1Moves: 4,
    hint: 'Запомни две пары и открой их по очереди.',
    explanation: 'Найди одинаковые карточки, переворачивая по две за ход.',
  ),
  MemoryLevel(
    pairs: 2,
    columns: 4,
    rows: 1,
    emojiSet: ['🍎', '🍌'],
    idealMoves: 2,
    stars2Moves: 3,
    stars1Moves: 4,
    hint: 'Внимательно посмотри, где какая карточка.',
    explanation: 'Пары одинаковых картинок нужно открыть друг за другом.',
  ),
  MemoryLevel(
    pairs: 3,
    columns: 3,
    rows: 2,
    emojiSet: ['⭐', '🚗', '🌻'],
    idealMoves: 3,
    stars2Moves: 4,
    stars1Moves: 5,
    hint: 'Не спеши — запоминай расположение карточек.',
    explanation: 'Чем больше пар — тем важнее запоминать позиции.',
  ),
  MemoryLevel(
    pairs: 3,
    columns: 2,
    rows: 3,
    emojiSet: ['🦊', '🐼', '🐸'],
    idealMoves: 3,
    stars2Moves: 4,
    stars1Moves: 6,
    hint: 'Повтори в уме: где лежит каждая картинка.',
    explanation: 'Тренируй память: сначала запомни, потом открывай пары.',
  ),
  MemoryLevel(
    pairs: 4,
    columns: 4,
    rows: 2,
    emojiSet: ['🍕', '🎈', '🧸', '🔍'],
    idealMoves: 4,
    stars2Moves: 5,
    stars1Moves: 7,
    hint: 'Запоминай по 1–2 карточки за раз.',
    explanation: 'Лучший способ — не угадывать, а запоминать.',
  ),
  MemoryLevel(
    pairs: 4,
    columns: 2,
    rows: 4,
    emojiSet: ['⚽', '🎧', '📚', '🛴'],
    idealMoves: 4,
    stars2Moves: 6,
    stars1Moves: 8,
    hint: 'Сосредоточься и запомни расположение.',
    explanation: 'Постепенно поле становится больше — тренируй внимательность.',
  ),
  MemoryLevel(
    pairs: 5,
    columns: 5,
    rows: 2,
    emojiSet: ['🌙', '☀️', '🌈', '⛄', '🌊'],
    idealMoves: 5,
    stars2Moves: 7,
    stars1Moves: 9,
    hint: 'Найди стратегию: запомнил — сразу открывай пару.',
    explanation: 'Планируй: сначала исследуй поле, запомни, потом собери пары.',
  ),
  MemoryLevel(
    pairs: 5,
    columns: 2,
    rows: 5,
    emojiSet: ['🦄', '🐝', '🦋', '🐞', '🌺'],
    idealMoves: 5,
    stars2Moves: 7,
    stars1Moves: 9,
    hint: 'Не торопись, смотри внимательно.',
    explanation: 'Запоминание помогает делать меньше ходов.',
  ),
  MemoryLevel(
    pairs: 6,
    columns: 4,
    rows: 3,
    emojiSet: ['🏀', '🎹', '🚀', '🧩', '💡', '🎯'],
    idealMoves: 6,
    stars2Moves: 8,
    stars1Moves: 10,
    hint: 'Разбей поле в уме на части и запоминай по блокам.',
    explanation: 'Увеличивай нагрузку постепенно — память крепчает.',
  ),
  MemoryLevel(
    pairs: 6,
    columns: 3,
    rows: 4,
    emojiSet: ['🍓', '🥝', '🍍', '🥕', '🍇', '🍔'],
    idealMoves: 6,
    stars2Moves: 8,
    stars1Moves: 11,
    hint: 'Запомни пару, как только увидел обе карточки.',
    explanation:
        'Полезно возвращаться мыслью к тем позициям, что уже открывал.',
  ),
  MemoryLevel(
    pairs: 7,
    columns: 4,
    rows: 4,
    emojiSet: ['⛵', '🏝️', '🗻', '🌲', '🔥', '💧', '🌾'],
    idealMoves: 7,
    stars2Moves: 9,
    stars1Moves: 12,
    hint: 'Старайся не переворачивать всё подряд.',
    explanation: 'Запоминание эффективнее случайных попыток.',
  ),
  MemoryLevel(
    pairs: 7,
    columns: 7,
    rows: 2,
    emojiSet: ['🎒', '🖍️', '📏', '🧷', '📌', '✂️', '📓'],
    idealMoves: 7,
    stars2Moves: 9,
    stars1Moves: 12,
    hint: 'Веди счёт в голове: где какая картинка лежит.',
    explanation: 'Тренировка памяти развивает внимание и усидчивость.',
  ),
  MemoryLevel(
    pairs: 8,
    columns: 4,
    rows: 4,
    emojiSet: ['🐙', '🦑', '🐠', '🐬', '🦞', '🪼', '🦈', '🐡'],
    idealMoves: 8,
    stars2Moves: 10,
    stars1Moves: 13,
    hint: 'Сохраняй спокойствие — не нужно торопиться.',
    explanation: 'Лучший результат — когда ты думаешь, а не спешишь.',
  ),
  MemoryLevel(
    pairs: 8,
    columns: 8,
    rows: 2,
    emojiSet: ['🚲', '✈️', '🚁', '⛴️', '🛸', '🚂', '🛻', '🚚'],
    idealMoves: 8,
    stars2Moves: 10,
    stars1Moves: 13,
    hint: 'Проверяй по памяти: сначала вспомни, потом открывай.',
    explanation:
        'Идеальный ход — открыть пару с первой попытки после запоминания.',
  ),
  MemoryLevel(
    pairs: 8,
    columns: 4,
    rows: 4,
    emojiSet: ['🟡', '🟢', '🔵', '🟣', '🔴', '🟠', '⚪', '🟤'],
    idealMoves: 8,
    stars2Moves: 11,
    stars1Moves: 14,
    hint: 'Сосредоточь внимание на цветах и формах — запоминай детали.',
    explanation: 'Самый сложный уровень — собери все пары, не теряя терпения!',
  ),
];
