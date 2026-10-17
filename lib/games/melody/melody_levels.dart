import 'package:flutter/material.dart';

/// Нота мелодии — семь ступеней от «До» до «Си».
///
/// [label] — слог, который видит ребёнок; [step] — номер ступени (1…7);
/// [color] — цвет кнопки и плитки ноты, чтобы ноты легко различать.
enum MusicNote {
  doNote('До', 1, Color(0xFFE84393)),
  re('Ре', 2, Color(0xFFFF9F43)),
  mi('Ми', 3, Color(0xFFF7B731)),
  fa('Фа', 4, Color(0xFF00B894)),
  sol('Соль', 5, Color(0xFF0984E3)),
  la('Ля', 6, Color(0xFF6C5CE7)),
  si('Си', 7, Color(0xFFE17055));

  const MusicNote(this.label, this.step, this.color);

  final String label;
  final int step;
  final Color color;
}

/// Описание одного уровня игры «Собери мелодию».
///
/// [target] — правильная мелодия: ноты, которые ребёнок должен выложить по
/// порядку. [palette] — доступные кнопки-ноты (может содержать лишние
/// ноты-«обманки»). Уровень решается, если каждая нота из [target] есть в
/// [palette] — это проверяет [debugIsSolvable].
class MelodyLevel {
  const MelodyLevel({
    required this.title,
    required this.target,
    required this.palette,
    required this.hint,
    required this.explanation,
  });

  /// Название мелодии (показывается ребёнку).
  final String title;

  /// Правильная последовательность нот.
  final List<MusicNote> target;

  /// Ноты, доступные на кнопках (может быть больше, чем нужно).
  final List<MusicNote> palette;

  /// Мягкая подсказка по уровню.
  final String hint;

  /// Короткое объяснение после победы.
  final String explanation;
}

/// 15 уровней — от простого к сложному: сначала 3 ноты и лесенка вверх,
/// затем спуски, «прыжки» через ноту, повторы и, наконец, целая мелодия.
const List<MelodyLevel> _melodyLevels = [
  // 1. Три ноты подряд вверх — самый простой уровень.
  MelodyLevel(
    title: 'Лесенка вверх',
    target: [MusicNote.doNote, MusicNote.re, MusicNote.mi],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi],
    hint: 'Ноты идут вверх по порядку: До, Ре, Ми.',
    explanation: 'Три ноты подряд вверх — и получилась весёлая лесенка! 🎵',
  ),
  // 2. Те же ноты, но сверху вниз.
  MelodyLevel(
    title: 'Лесенка вниз',
    target: [MusicNote.mi, MusicNote.re, MusicNote.doNote],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi],
    hint: 'Теперь наоборот — ноты спускаются: Ми, Ре, До.',
    explanation: 'Если петь ноты сверху вниз, мелодия идёт как с горки.',
  ),
  // 3. Прыжок через ноту туда и обратно.
  MelodyLevel(
    title: 'Качели',
    target: [MusicNote.doNote, MusicNote.mi, MusicNote.doNote],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi],
    hint: 'Прыжок через ноту: До, Ми, До.',
    explanation: 'Мы перепрыгнули через Ре — получились «качели»: До, Ми, До.',
  ),
  // 4. Четыре ноты вверх.
  MelodyLevel(
    title: 'Четыре ступеньки',
    target: [MusicNote.doNote, MusicNote.re, MusicNote.mi, MusicNote.fa],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi, MusicNote.fa],
    hint: 'Поднимайся по ноткам: До, Ре, Ми, Фа.',
    explanation: 'Четыре ноты подряд вверх — уже целая лесенка!',
  ),
  // 5. Четыре ноты вниз.
  MelodyLevel(
    title: 'Спуск с горки',
    target: [MusicNote.fa, MusicNote.mi, MusicNote.re, MusicNote.doNote],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi, MusicNote.fa],
    hint: 'Спускаемся вниз: Фа, Ми, Ре, До.',
    explanation: 'Теперь мелодия спускается вниз по ноткам, как с горки.',
  ),
  // 6. «Прыжки» через ноту — До, Ми, Соль.
  MelodyLevel(
    title: 'Прыжок вверх',
    target: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    palette: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    hint: 'Через одну нотку: До, Ми, Соль.',
    explanation: 'До, Ми, Соль — это «прыжки» через ноту. Получился аккорд!',
  ),
  // 7. Повторы: ритмический узор.
  MelodyLevel(
    title: 'Тук-тук',
    target: [MusicNote.sol, MusicNote.sol, MusicNote.mi, MusicNote.mi],
    palette: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    hint: 'Повторяй каждую ноту два раза: Соль, Соль, Ми, Ми.',
    explanation: 'Когда ноты повторяются, мелодия звучит как стук: тук-тук!',
  ),
  // 8. Вверх и обратно.
  MelodyLevel(
    title: 'Вверх-вниз',
    target: [MusicNote.doNote, MusicNote.mi, MusicNote.sol, MusicNote.mi],
    palette: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    hint: 'Поднялись и вернулись: До, Ми, Соль, Ми.',
    explanation: 'Сначала вверх по прыжкам, потом — назад. Мелодия как волна.',
  ),
  // 9. Повторяющийся узор «эхо».
  MelodyLevel(
    title: 'Эхо',
    target: [
      MusicNote.sol,
      MusicNote.mi,
      MusicNote.sol,
      MusicNote.mi,
      MusicNote.doNote,
    ],
    palette: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    hint: 'Слушай узор: Соль, Ми, Соль, Ми, а потом До.',
    explanation: 'Соль и Ми повторяются как эхо, а в конце — низкая нота До.',
  ),
  // 10. Пять нот вверх.
  MelodyLevel(
    title: 'Пять ступенек',
    target: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.fa,
      MusicNote.sol,
    ],
    palette: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.fa,
      MusicNote.sol,
    ],
    hint: 'Вся лесенка вверх: До, Ре, Ми, Фа, Соль.',
    explanation: 'Пять нот подряд вверх — от До до Соль.',
  ),
  // 11. Пять нот вниз.
  MelodyLevel(
    title: 'Пять с горки',
    target: [
      MusicNote.sol,
      MusicNote.fa,
      MusicNote.mi,
      MusicNote.re,
      MusicNote.doNote,
    ],
    palette: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.fa,
      MusicNote.sol,
    ],
    hint: 'Вся лесенка вниз: Соль, Фа, Ми, Ре, До.',
    explanation: 'Пять нот подряд вниз — от Соль обратно к До.',
  ),
  // 12. Высокая и низкая ноты по очереди — «кукушка».
  MelodyLevel(
    title: 'Песенка кукушки',
    target: [
      MusicNote.sol,
      MusicNote.mi,
      MusicNote.doNote,
      MusicNote.mi,
      MusicNote.sol,
    ],
    palette: [MusicNote.doNote, MusicNote.mi, MusicNote.sol],
    hint: 'Ку-ку: Соль, Ми, До, Ми, Соль.',
    explanation: 'Высокая и низкая ноты по очереди — будто кукушка поёт.',
  ),
  // 13. Волна с лишней нотой в палитре (обманка).
  MelodyLevel(
    title: 'Пёстрая волна',
    target: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.re,
      MusicNote.doNote,
      MusicNote.mi,
    ],
    palette: [MusicNote.doNote, MusicNote.re, MusicNote.mi, MusicNote.fa],
    hint: 'Вверх, чуть вниз и снова вверх: До, Ре, Ми, Ре, До, Ми.',
    explanation: 'Мелодия качается как волна. Нота Фа здесь не понадобилась!',
  ),
  // 14. Самые высокие ноты — Ля и Си.
  MelodyLevel(
    title: 'Высокие ноты',
    target: [
      MusicNote.sol,
      MusicNote.la,
      MusicNote.si,
      MusicNote.la,
      MusicNote.sol,
    ],
    palette: [
      MusicNote.doNote,
      MusicNote.mi,
      MusicNote.sol,
      MusicNote.la,
      MusicNote.si,
    ],
    hint: 'Поднимаемся к высоким нотам: Соль, Ля, Си, Ля, Соль.',
    explanation: 'Ля и Си — самые высокие ноты. Получилась красивая арка.',
  ),
  // 15. Финал: вся мелодия из семи нот вверх и плавно вниз к До.
  MelodyLevel(
    title: 'Целая песенка',
    target: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.fa,
      MusicNote.sol,
      MusicNote.la,
      MusicNote.si,
      MusicNote.sol,
      MusicNote.mi,
      MusicNote.doNote,
    ],
    palette: [
      MusicNote.doNote,
      MusicNote.re,
      MusicNote.mi,
      MusicNote.fa,
      MusicNote.sol,
      MusicNote.la,
      MusicNote.si,
    ],
    hint: 'Настоящая мелодия: вверх до высоты и обратно домой к До.',
    explanation:
        'Вот это мелодия! Сначала вверх по всем нотам, потом — '
        'плавно вниз к До. 🎉',
  ),
];

/// Уровни игры (открыты для автотестов, как в других играх проекта).
List<MelodyLevel> get melodyLevels => _melodyLevels;

/// Простая проверка уровня (не тест): цель непустая и каждая её нота есть
/// среди кнопок палитры — значит уровень гарантированно решается.
bool debugIsSolvable(MelodyLevel lvl) {
  if (lvl.target.isEmpty) return false;
  if (lvl.palette.isEmpty) return false;
  final available = lvl.palette.toSet();
  return lvl.target.every(available.contains);
}

/// Проверяет сразу все уровни (удобно дёрнуть вручную или из отладки).
bool debugAllLevelsSolvable() => _melodyLevels.every(debugIsSolvable);
