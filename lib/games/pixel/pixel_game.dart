import 'dart:async';

import 'package:flutter/material.dart';

import '../../blocks/block_model.dart';
import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/block_editor.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';

/// Команды кисточки в игре «Пиксель-арт».
const BlockCommandDef kPaint = BlockCommandDef(
  id: 'paint',
  icon: Icons.brush_rounded,
  label: 'Закрась',
);
const BlockCommandDef kRight = BlockCommandDef(
  id: 'right',
  icon: Icons.arrow_forward_rounded,
  label: 'Вправо',
);
const BlockCommandDef kDown = BlockCommandDef(
  id: 'down',
  icon: Icons.arrow_downward_rounded,
  label: 'Вниз',
);
const BlockCommandDef kLeft = BlockCommandDef(
  id: 'left',
  icon: Icons.arrow_back_rounded,
  label: 'Влево',
);
const BlockCommandDef kUp = BlockCommandDef(
  id: 'up',
  icon: Icons.arrow_upward_rounded,
  label: 'Вверх',
);

/// Доступные блоки пиксель-арта (условия нет — только команды и цикл).
const List<BlockCommandDef> kPixelBlocks = [kPaint, kRight, kDown, kLeft, kUp];

/// Цвета кисточки: 1 — красный, 2 — синий, 3 — жёлтый, 4 — зелёный.
/// Ноль зарезервирован за «пустой» клеткой (базовый цвет).
const Map<int, String> kPixelColorNames = {
  1: 'красный',
  2: 'синий',
  3: 'жёлтый',
  4: 'зелёный',
};

/// Эмодзи цветов — для подсказок и палитры.
const Map<int, String> kPixelColorEmoji = {
  1: '🔴',
  2: '🔵',
  3: '🟡',
  4: '🟢',
};

/// Материальные цвета палитры по номеру цвета.
const Map<int, Color> kPixelColorValues = {
  1: Color(0xFFE53935),
  2: Color(0xFF1E88E5),
  3: Color(0xFFFDD835),
  4: Color(0xFF43A047),
};

/// Команды выбора цвета кисти (появляются на цветных уровнях).
const BlockCommandDef kColorRed = BlockCommandDef(
  id: 'color_red',
  icon: Icons.circle,
  label: 'Цвет: красный',
  color: Color(0xFFE53935),
);
const BlockCommandDef kColorBlue = BlockCommandDef(
  id: 'color_blue',
  icon: Icons.circle,
  label: 'Цвет: синий',
  color: Color(0xFF1E88E5),
);
const BlockCommandDef kColorYellow = BlockCommandDef(
  id: 'color_yellow',
  icon: Icons.circle,
  label: 'Цвет: жёлтый',
  color: Color(0xFFFDD835),
);
const BlockCommandDef kColorGreen = BlockCommandDef(
  id: 'color_green',
  icon: Icons.circle,
  label: 'Цвет: зелёный',
  color: Color(0xFF43A047),
);

/// Блоки выбора цвета в том же порядке, что и номера цветов 1..4.
const List<BlockCommandDef> kPixelColorBlocks = [
  kColorRed,
  kColorBlue,
  kColorYellow,
  kColorGreen,
];

/// Номер цвета по id команды выбора цвета (0 — команда не про цвет).
int pixelColorOfCommand(String id) {
  const ids = ['color_red', 'color_blue', 'color_yellow', 'color_green'];
  final index = ids.indexOf(id);
  return index < 0 ? 0 : index + 1;
}

/// Один шаг симуляции (состояние поля после команды).
class PixelStep {
  const PixelStep({
    required this.painted,
    required this.cursor,
    required this.commandId,
    this.colors = const {},
  });

  final Set<int> painted;
  final int cursor;
  final String commandId;

  /// Цвет каждой закрашенной клетки (0 — базовый цвет, 1..4 — палитра).
  final Map<int, int> colors;
}

/// Результат симуляции программы.
class PixelSim {
  PixelSim({
    required this.steps,
    required this.finalPainted,
    required this.hitLimit,
    this.finalColors = const {},
  });

  final List<PixelStep> steps;
  final Set<int> finalPainted;
  final bool hitLimit;

  /// Цвет каждой закрашенной клетки в конце программы.
  final Map<int, int> finalColors;
}

/// Выполняет программу на поле пиксель-арта и возвращает все шаги.
///
/// Кисточка стартует в (0, 0). Команды «Вправо»/«Вниз»/… выходят за границы
/// поля — команда просто пропускается (кисточка остаётся на месте).
/// Команды «Цвет: …» меняют цвет кисти, которым красит «Закрась».
PixelSim simulatePixel(
  List<BlockNode> program,
  int cols,
  int rows, {
  int maxSteps = kBlockMaxSteps,
}) {
  final colors = <int, int>{};
  final steps = <PixelStep>[];
  var x = 0;
  var y = 0;
  var count = 0;
  var hitLimit = false;
  var brush = 0;

  void rec(List<BlockNode> nodes) {
    for (final node in nodes) {
      if (hitLimit) return;
      if (count >= maxSteps) {
        hitLimit = true;
        return;
      }
      switch (node) {
        case CommandBlock():
          count++;
          final color = pixelColorOfCommand(node.def.id);
          if (color != 0) {
            brush = color;
          } else {
            switch (node.def.id) {
              case 'paint':
                colors[y * cols + x] = brush;
              case 'right':
                if (x < cols - 1) x++;
              case 'down':
                if (y < rows - 1) y++;
              case 'left':
                if (x > 0) x--;
              case 'up':
                if (y > 0) y--;
            }
          }
          steps.add(PixelStep(
            painted: Set.of(colors.keys),
            cursor: y * cols + x,
            commandId: node.def.id,
            colors: Map.of(colors),
          ));
        case RepeatBlock():
          for (var i = 0; i < node.times; i++) {
            rec(node.body);
            if (hitLimit) return;
          }
        case IfBlock():
          rec(node.body);
        case FunctionCallBlock():
          rec(node.function.body);
      }
    }
  }

  rec(program);
  return PixelSim(
    steps: steps,
    finalPainted: colors.keys.toSet(),
    hitLimit: hitLimit,
    finalColors: Map.of(colors),
  );
}

/// Описание уровня пиксель-арта.
class PixelLevel {
  const PixelLevel({
    required this.cols,
    required this.rows,
    required this.target,
    required this.hint,
    this.colorTarget,
  });

  final int cols;
  final int rows;

  /// Клетки, которые нужно закрасить (индекс = x + y * cols).
  final Set<int> target;

  /// Для цветных уровней: клетка → номер цвета (1..4).
  /// Если null — уровень без цветов (сравниваются только клетки).
  final Map<int, int>? colorTarget;

  final String hint;
}

/// Уровни пиксель-арта (45 штук, от простого к сложному).
const List<PixelLevel> _pixelLevels = [
  PixelLevel(
    cols: 2,
    rows: 2,
    target: {0},
    hint: 'Просто нажми «Закрась» и запусти программу.',
  ),
  PixelLevel(
    cols: 6,
    rows: 3,
    target: {6, 7, 8, 9, 10, 11},
    hint: 'Линия из шести клеток — помоги циклом: «Закрась, вправо».',
  ),
  PixelLevel(
    cols: 3,
    rows: 6,
    target: {1, 4, 7, 10, 13, 16},
    hint: 'Теперь столбик: «Закрась, вниз» и повтори!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 3, 4, 9, 14, 19, 24},
    hint: 'Уголок: сначала закрась верхнюю линию, потом правый столбик.',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 6, 12, 18, 24},
    hint: 'Диагональ: цикл «Закрась, вправо, вниз».',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 5, 6, 7, 10, 11, 12},
    hint: 'Квадрат из девяти клеток: внутри цикла ещё один цикл!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 5, 10, 15, 20, 2, 7, 12, 17, 22},
    hint: 'Два столбика: закрась первый циклом, вернись и закрась второй.',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 2, 4, 10, 12, 14, 20, 22, 24},
    hint: 'Шашечки: закрашивай клетку, пропускай одну. Дважды повторить!',
  ),
  PixelLevel(
    cols: 6,
    rows: 6,
    target: {0, 1, 6, 7, 12, 13, 18, 19},
    hint: 'Прямоугольник 2 на 4: вложенные циклы снова в деле!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 3, 4, 5, 9, 10, 14, 15, 19, 20, 21, 22, 23, 24},
    hint: 'Рамка вокруг всего поля: четыре цикла — верх, вниз по стенке, низ и обратно.',
  ),
  // 11: буква «П» — верхняя линия и две ножки.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 13, 14, 20, 21, 27, 28, 34, 35, 41, 42, 48},
    hint: 'Буква «П»: сначала нарисуй верхнюю линию, потом спустись вниз по правой ножке и поднимись по левой.',
  ),
  // 12: шахматный узор — клетки через одну «змейкой».
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39,
      41, 43, 45, 47,
    },
    hint: 'Шахматный узор: закрашивай через клетку. Строки идут «змейкой» — то вправо, то влево.',
  ),
  // 13: сердечко — широкие строки, к низу сужается.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      1, 2, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
      23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 37, 38, 39, 45,
    },
    hint: 'Сердечко: две «ямочки» сверху, потом целые широкие строки, а книзу оно сужается до одной клетки.',
  ),
  // 14: ёлочка — треугольник из строк разной длины и ствол.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      3, 9, 10, 11, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 31, 38, 45,
    },
    hint: 'Ёлочка: каждая строка треугольника шире предыдущей, а в самом низу — маленький ствол.',
  ),
  // 15: две параллельные диагонали.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {0, 1, 10, 11, 20, 21, 30, 31, 40, 41, 50, 51, 60, 61, 70, 71, 80},
    hint: 'Две параллельные диагонали: нарисуй одну по диагонали, вернись назад и нарисуй вторую рядом.',
  ),
  // 16: две горизонтальные полосы — по строкам.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {
      16, 17, 18, 19, 20, 21, 22, 23, 40, 41, 42, 43, 44, 45, 46, 47,
    },
    hint: 'Две горизонтальные полоски: спустись вниз и закрась строку вправо циклом, потом спусти ещё ниже и закрась строку влево.',
  ),
  // 17: рамка вокруг всего поля 8×8.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {
      0, 1, 2, 3, 4, 5, 6, 7, 8, 15, 16, 23, 24, 31, 32, 39, 40, 47, 48, 55,
      56, 57, 58, 59, 60, 61, 62, 63,
    },
    hint: 'Большая рамка: обойди всё поле по периметру, закрашивая клетку за клеткой. Четыре цикла — по одной стороне квадрата.',
  ),
  // 18: буква Т — верхняя перекладина и средний столбик.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {0, 1, 2, 3, 4, 5, 6, 10, 17, 24, 31, 38, 45},
    hint: 'Буква «Т»: сверху широкая перекладина, а из её середины вниз спускается длинный столбик.',
  ),
  // 19: буква Г — верхняя перекладина и правый столбик.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {0, 1, 2, 3, 4, 5, 6, 13, 20, 27, 34, 41, 48},
    hint: 'Буква «Г»: проведи верхнюю линию вправо, а потом от правого края спускайся вниз до самого низа.',
  ),
  // 20: лесенка — ступеньки по диагонали.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 1, 9, 10, 18, 19, 27, 36},
    hint: 'Лесенка идёт вниз-вправо по диагонали. Каждая ступенька — две клетки рядом: закрась, шагни вправо и вниз, и снова закрась.',
  ),
  // 21: крест — вертикаль и горизонталь пересекаются.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {
      4, 13, 22, 31, 36, 37, 38, 39, 40, 41, 42, 43, 44, 49, 58, 67, 76,
    },
    hint: 'Крест: сначала дойди до середины сверху и нарисуй длинный столбик вниз, потом вернись в центр и проведи поперечную линию.',
  ),
  // 22: штриховые столбики в каждом втором столбце.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {
      0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38,
      40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62,
    },
    hint: 'Штриховые столбики: рисуй полный столбик вниз, потом два шага вправо, а там столбик вверх. Так поочерёдно до конца.',
  ),
  // 23: стрелка вправо — линия и два штриха-оперения.
  PixelLevel(
    cols: 9,
    rows: 7,
    target: {33, 36, 37, 38, 39, 40, 41, 42, 51},
    hint: 'Стрелка вправо: длинная линия посередине, а от её правого конца отходят два маленьких штриха — вверх и вниз.',
  ),
  // 24: буква U — две линии и соединение снизу.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {1, 5, 8, 12, 15, 19, 22, 26, 29, 33, 36, 40, 43, 44, 45, 46, 47},
    hint: 'Буква «U»: проведи левую линию вниз, соедини её с правой нижней перемычкой, а потом проведи правую линию вверх.',
  ),
  // 25: буква М — две стороны и острый изгиб посередине.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      0, 6, 7, 8, 12, 13, 14, 16, 18, 20, 21, 24, 27, 28, 34, 35, 41, 42, 48,
    },
    hint: 'Буква «М»: две высокие стороны по краям, а между ними — острый угол, который сходится внизу к середине.',
  ),
  // 26: буква Л — линия справа и диагональ вниз-влево.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {6, 12, 13, 18, 20, 24, 27, 30, 34, 36, 41, 42, 48},
    hint: 'Форма буквы «Л»: длинная линия справа, а от её верха косая линия спускается вниз-влево до самого угла.',
  ),
  // 27: ёлка — ярусы треугольником и ствол.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {
      4, 12, 13, 14, 20, 21, 22, 23, 24, 28, 29, 30, 31, 32, 33, 40, 49,
    },
    hint: 'Ёлка: сверху маленькая шапочка, каждый следующий ярус шире предыдущего, а внизу — узкий стволик из двух клеток.',
  ),
  // 28: крест-диагонали — буква X.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {
      0, 8, 10, 16, 20, 24, 30, 32, 40, 48, 50, 56, 60, 64, 70, 72, 80,
    },
    hint: 'Буква «X»: две длинные диагонали пересекаются в самом центре. Нарисуй первую до конца, вернись в начало и проведи вторую.',
  ),
  // 29: шахматный узор змейкой — строки через клетку.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {
      0, 2, 4, 6, 9, 11, 13, 15, 16, 18, 20, 22, 25, 27, 29, 31, 32, 34, 36, 38,
      41, 43, 45, 47, 48, 50, 52, 54, 57, 59, 61, 63,
    },
    hint: 'Шахматный узор большого размера: в каждой строке закрашивай клетку через одну. Строки идут змейкой — вправо, вниз, влево, вниз.',
  ),
  // 30: пять полос через строку — большая змейка.
  PixelLevel(
    cols: 10,
    rows: 10,
    target: {
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
      40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 60, 61, 62, 63, 64, 65, 66, 67,
      68, 69, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
    },
    hint: 'Финал: пять длинных полос через одну строку. Закрась полосу вправо, спустись на две клетки вниз, закрась полосу влево — и так змейкой до самого низа!',
  ),
  // 31: две линии — красная сверху, синяя снизу.
  PixelLevel(
    cols: 6,
    rows: 6,
    target: {0, 1, 2, 3, 4, 5, 30, 31, 32, 33, 34, 35},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 30: 2, 31: 2, 32: 2, 33: 2, 34: 2, 35: 2,
    },
    hint: 'Новые блоки цвета! Сначала выбери 🔴 и закрась верхнюю полосу, потом 🔵 — нижнюю.',
  ),
  // 32: три полосы — красная, синяя, зелёная.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 32, 33, 34, 35, 36, 37, 38, 39, 56, 57, 58, 59, 60, 61, 62, 63},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2, 38: 2, 39: 2,
      56: 4, 57: 4, 58: 4, 59: 4, 60: 4, 61: 4, 62: 4, 63: 4,
    },
    hint: 'Три полосы и три цвета: 🔴 сверху, 🔵 посередине, 🟢 снизу.',
  ),
  // 33: три столбца — красный, жёлтый, синий.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {0, 3, 6, 7, 10, 13, 14, 17, 20, 21, 24, 27, 28, 31, 34, 35, 38, 41, 42, 45, 48},
    colorTarget: {
      0: 1, 3: 3, 6: 2, 7: 1, 10: 3, 13: 2, 14: 1, 17: 3,
      20: 2, 21: 1, 24: 3, 27: 2, 28: 1, 31: 3, 34: 2, 35: 1,
      38: 3, 41: 2, 42: 1, 45: 3, 48: 2,
    },
    hint: 'Три столбца разного цвета: 🔴 слева, 🟡 в середине, 🔵 справа. Кисточка ходит вниз и вверх.',
  ),
  // 34: две диагонали — красная и синяя.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 7, 9, 14, 18, 21, 27, 28, 35, 36, 42, 45, 49, 54, 56, 63},
    colorTarget: {
      0: 1, 7: 2, 9: 1, 14: 2, 18: 1, 21: 2, 27: 1, 28: 2,
      35: 2, 36: 1, 42: 2, 45: 1, 49: 2, 54: 1, 56: 2, 63: 1,
    },
    hint: 'Две цветные диагонали: 🔴 наискосок вправо-вниз, 🔵 — влево-вниз.',
  ),
  // 35: две половинки — верх красный, низ синий.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1,
      16: 1, 17: 1, 18: 1, 19: 1, 20: 1, 21: 1, 22: 1, 23: 1,
      24: 1, 25: 1, 26: 1, 27: 1, 28: 1, 29: 1, 30: 1, 31: 1,
      32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2, 38: 2, 39: 2,
      40: 2, 41: 2, 42: 2, 43: 2, 44: 2, 45: 2, 46: 2, 47: 2,
      48: 2, 49: 2, 50: 2, 51: 2, 52: 2, 53: 2, 54: 2, 55: 2,
      56: 2, 57: 2, 58: 2, 59: 2, 60: 2, 61: 2, 62: 2, 63: 2,
    },
    hint: 'Вся картинка из двух цветов: верхняя половина 🔴 красная, нижняя 🔵 синяя.',
  ),
  // 36: четыре вертикальные полосы шириной в две клетки.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63},
    colorTarget: {
      0: 1, 1: 1, 2: 2, 3: 2, 4: 3, 5: 3, 6: 1, 7: 1,
      8: 1, 9: 1, 10: 2, 11: 2, 12: 3, 13: 3, 14: 1, 15: 1,
      16: 1, 17: 1, 18: 2, 19: 2, 20: 3, 21: 3, 22: 1, 23: 1,
      24: 1, 25: 1, 26: 2, 27: 2, 28: 3, 29: 3, 30: 1, 31: 1,
      32: 1, 33: 1, 34: 2, 35: 2, 36: 3, 37: 3, 38: 1, 39: 1,
      40: 1, 41: 1, 42: 2, 43: 2, 44: 3, 45: 3, 46: 1, 47: 1,
      48: 1, 49: 1, 50: 2, 51: 2, 52: 3, 53: 3, 54: 1, 55: 1,
      56: 1, 57: 1, 58: 2, 59: 2, 60: 3, 61: 3, 62: 1, 63: 1,
    },
    hint: 'Четыре широких столбца: 🔴, 🔵, 🟡 и снова 🔴 — по два столбика каждый!',
  ),
  // 37: крест — красный столбик и синяя поперечина.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {3, 4, 11, 12, 19, 20, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 43, 44, 51, 52, 59, 60},
    colorTarget: {
      3: 1, 4: 1, 11: 1, 12: 1, 19: 1, 20: 1, 24: 2, 25: 2,
      26: 2, 27: 1, 28: 1, 29: 2, 30: 2, 31: 2, 32: 2, 33: 2,
      34: 2, 35: 1, 36: 1, 37: 2, 38: 2, 39: 2, 43: 1, 44: 1,
      51: 1, 52: 1, 59: 1, 60: 1,
    },
    hint: 'Крест: длинный 🔴 столбик и поперечная 🔵 линия. В центре побеждает красный.',
  ),
  // 38: чередующиеся строки — красные и синие.
  PixelLevel(
    cols: 8,
    rows: 8,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2,
      16: 1, 17: 1, 18: 1, 19: 1, 20: 1, 21: 1, 22: 1, 23: 1,
      24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2,
      32: 1, 33: 1, 34: 1, 35: 1, 36: 1, 37: 1, 38: 1, 39: 1,
      40: 2, 41: 2, 42: 2, 43: 2, 44: 2, 45: 2, 46: 2, 47: 2,
      48: 1, 49: 1, 50: 1, 51: 1, 52: 1, 53: 1, 54: 1, 55: 1,
      56: 2, 57: 2, 58: 2, 59: 2, 60: 2, 61: 2, 62: 2, 63: 2,
    },
    hint: 'Полоски через строку: 🔴 и 🔵 чередуются. Кисточка идёт змейкой сверху вниз!',
  ),
  // 39: три полосы — красная, синяя, зелёная (10×6).
  PixelLevel(
    cols: 10,
    rows: 6,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1,
      16: 1, 17: 1, 18: 1, 19: 1, 20: 2, 21: 2, 22: 2, 23: 2,
      24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2,
      32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2, 38: 2, 39: 2,
      40: 4, 41: 4, 42: 4, 43: 4, 44: 4, 45: 4, 46: 4, 47: 4,
      48: 4, 49: 4, 50: 4, 51: 4, 52: 4, 53: 4, 54: 4, 55: 4,
      56: 4, 57: 4, 58: 4, 59: 4,
    },
    hint: 'Большая картинка в три полосы: 🔴 сверху, 🔵 посередине, 🟢 снизу.',
  ),
  // 40: четыре полосы в три цвета — «радуга» (10×8).
  PixelLevel(
    cols: 10,
    rows: 8,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1,
      16: 1, 17: 1, 18: 1, 19: 1, 20: 2, 21: 2, 22: 2, 23: 2,
      24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2,
      32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2, 38: 2, 39: 2,
      40: 3, 41: 3, 42: 3, 43: 3, 44: 3, 45: 3, 46: 3, 47: 3,
      48: 3, 49: 3, 50: 3, 51: 3, 52: 3, 53: 3, 54: 3, 55: 3,
      56: 3, 57: 3, 58: 3, 59: 3, 60: 1, 61: 1, 62: 1, 63: 1,
      64: 1, 65: 1, 66: 1, 67: 1, 68: 1, 69: 1, 70: 1, 71: 1,
      72: 1, 73: 1, 74: 1, 75: 1, 76: 1, 77: 1, 78: 1, 79: 1,
    },
    hint: 'Радуга из трёх цветов: 🔴, 🔵, 🟡 и снова 🔴. Двигайся змейкой и меняй цвет!',
  ),
  // 41: два квадрата по углам — красный и синий.
  PixelLevel(
    cols: 10,
    rows: 10,
    target: {0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24, 30, 31, 32, 33, 34, 40, 41, 42, 43, 44, 55, 56, 57, 58, 59, 65, 66, 67, 68, 69, 75, 76, 77, 78, 79, 85, 86, 87, 88, 89, 95, 96, 97, 98, 99},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 10: 1, 11: 1, 12: 1,
      13: 1, 14: 1, 20: 1, 21: 1, 22: 1, 23: 1, 24: 1, 30: 1,
      31: 1, 32: 1, 33: 1, 34: 1, 40: 1, 41: 1, 42: 1, 43: 1,
      44: 1, 55: 2, 56: 2, 57: 2, 58: 2, 59: 2, 65: 2, 66: 2,
      67: 2, 68: 2, 69: 2, 75: 2, 76: 2, 77: 2, 78: 2, 79: 2,
      85: 2, 86: 2, 87: 2, 88: 2, 89: 2, 95: 2, 96: 2, 97: 2,
      98: 2, 99: 2,
    },
    hint: 'Два квадрата 5×5 по углам: левый верхний 🔴, правый нижний 🔵.',
  ),
  // 42: красная рамка и синяя диагональ.
  PixelLevel(
    cols: 10,
    rows: 10,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 19, 20, 22, 29, 30, 33, 39, 40, 44, 49, 50, 55, 59, 60, 66, 69, 70, 77, 79, 80, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99},
    colorTarget: {
      0: 2, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 1, 10: 1, 11: 2, 19: 1, 20: 1, 22: 2, 29: 1,
      30: 1, 33: 2, 39: 1, 40: 1, 44: 2, 49: 1, 50: 1, 55: 2,
      59: 1, 60: 1, 66: 2, 69: 1, 70: 1, 77: 2, 79: 1, 80: 1,
      88: 2, 89: 1, 90: 1, 91: 1, 92: 1, 93: 1, 94: 1, 95: 1,
      96: 1, 97: 1, 98: 1, 99: 2,
    },
    hint: 'Рамка 🔴 и диагональ 🔵. Сначала обойди рамку красным, потом проведи синюю диагональ — она перекрасит уголки!',
  ),
  // 43: красная рамка и синий центр 3×3.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 18, 26, 27, 30, 31, 32, 35, 36, 39, 40, 41, 44, 45, 48, 49, 50, 53, 54, 62, 63, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 1, 17: 1, 18: 1, 26: 1, 27: 1, 30: 2, 31: 2,
      32: 2, 35: 1, 36: 1, 39: 2, 40: 2, 41: 2, 44: 1, 45: 1,
      48: 2, 49: 2, 50: 2, 53: 1, 54: 1, 62: 1, 63: 1, 71: 1,
      72: 1, 73: 1, 74: 1, 75: 1, 76: 1, 77: 1, 78: 1, 79: 1,
      80: 1,
    },
    hint: 'Рамка 🔴 и квадратик 🔵 в самом центре.',
  ),
  // 44: три вертикальные полосы шириной в три клетки (9×10).
  PixelLevel(
    cols: 9,
    rows: 10,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89},
    colorTarget: {
      0: 1, 1: 1, 2: 1, 3: 2, 4: 2, 5: 2, 6: 3, 7: 3,
      8: 3, 9: 1, 10: 1, 11: 1, 12: 2, 13: 2, 14: 2, 15: 3,
      16: 3, 17: 3, 18: 1, 19: 1, 20: 1, 21: 2, 22: 2, 23: 2,
      24: 3, 25: 3, 26: 3, 27: 1, 28: 1, 29: 1, 30: 2, 31: 2,
      32: 2, 33: 3, 34: 3, 35: 3, 36: 1, 37: 1, 38: 1, 39: 2,
      40: 2, 41: 2, 42: 3, 43: 3, 44: 3, 45: 1, 46: 1, 47: 1,
      48: 2, 49: 2, 50: 2, 51: 3, 52: 3, 53: 3, 54: 1, 55: 1,
      56: 1, 57: 2, 58: 2, 59: 2, 60: 3, 61: 3, 62: 3, 63: 1,
      64: 1, 65: 1, 66: 2, 67: 2, 68: 2, 69: 3, 70: 3, 71: 3,
      72: 1, 73: 1, 74: 1, 75: 2, 76: 2, 77: 2, 78: 3, 79: 3,
      80: 3, 81: 1, 82: 1, 83: 1, 84: 2, 85: 2, 86: 2, 87: 3,
      88: 3, 89: 3,
    },
    hint: 'Три широких столбца: 🔴, 🔵, 🟡. Проходи каждый столбик вверх-вниз циклом!',
  ),
  // 45: красная рамка и синий крест «X» (финал).
  PixelLevel(
    cols: 10,
    rows: 10,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 18, 19, 20, 22, 27, 29, 30, 33, 36, 39, 40, 44, 45, 49, 50, 54, 55, 59, 60, 63, 66, 69, 70, 72, 77, 79, 80, 81, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99},
    colorTarget: {
      0: 2, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1,
      8: 1, 9: 2, 10: 1, 11: 2, 18: 2, 19: 1, 20: 1, 22: 2,
      27: 2, 29: 1, 30: 1, 33: 2, 36: 2, 39: 1, 40: 1, 44: 2,
      45: 2, 49: 1, 50: 1, 54: 2, 55: 2, 59: 1, 60: 1, 63: 2,
      66: 2, 69: 1, 70: 1, 72: 2, 77: 2, 79: 1, 80: 1, 81: 2,
      88: 2, 89: 1, 90: 2, 91: 1, 92: 1, 93: 1, 94: 1, 95: 1,
      96: 1, 97: 1, 98: 1, 99: 2,
    },
    hint: 'Финал: рамка 🔴 и буква «X» 🔵 внутри. Нарисуй рамку, потом две диагонали!',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<PixelLevel> get pixelLevels => _pixelLevels;

/// Игра «Пиксель-арт»: рисуем картинку командами из блоков.
class PixelGame extends StatefulWidget {
  const PixelGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<PixelGame> createState() => _PixelGameState();
}

class _PixelGameState extends State<PixelGame> {
  late PixelLevel _level;
  final List<BlockNode> _program = [];

  Set<int> _painted = {};
  Map<int, int> _colors = {};
  int _cursor = 0;
  bool _running = false;
  bool _won = false;
  int _failedRuns = 0;
  String _status = '';

  static const GameInfo _game = GameInfo(
    id: 'pixel',
    title: 'Пиксель-арт',
    subtitle: '',
    emoji: '🎨',
    levelCount: 45,
  );

  @override
  void initState() {
    super.initState();
    _level = _pixelLevels[widget.levelIndex % _pixelLevels.length];
  }

  /// Уровень с цветами — рисуем красками, а не одним цветом.
  bool get _colorful => _level.colorTarget != null;

  void _restart() {
    setState(() {
      _program.clear();
      _painted = {};
      _colors = {};
      _cursor = 0;
      _won = false;
      _running = false;
      _failedRuns = 0;
      _status = '';
    });
  }

  /// Совпадают ли нарисованные цвета кисточки с цветными целями уровня.
  bool _colorsMatch(Map<int, int> target) {
    if (_colors.length != target.length) return false;
    for (final entry in target.entries) {
      if (_colors[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> _run() async {
    if (_program.isEmpty || _running || _won) return;
    setState(() {
      _running = true;
      _status = 'Кисточка рисует…';
      _painted = {};
      _colors = {};
      _cursor = 0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final sim = simulatePixel(_program, _level.cols, _level.rows);
    if (sim.hitLimit) {
      setState(() {
        _running = false;
        _failedRuns++;
        _status = 'Программа очень длинная — упрости её 🙂';
      });
      return;
    }
    for (final step in sim.steps) {
      if (!mounted) return;
      setState(() {
        _painted = step.painted;
        _colors = step.colors;
        _cursor = step.cursor;
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted) return;

    final ok = _colorful
        ? _colorsMatch(_level.colorTarget!)
        : _painted.length == _level.target.length &&
            _painted.containsAll(_level.target);
    if (ok) {
      final stars = (3 - _failedRuns).clamp(1, 3);
      setState(() {
        _running = false;
        _won = true;
        _status = 'Готово! Картинка получилась! 🎨';
      });
      widget.onFinished(stars);
    } else {
      final missing = _level.target.difference(_painted).length;
      final extra = _painted.difference(_level.target).length;
      setState(() {
        _running = false;
        _failedRuns++;
        if (_colorful && missing == 0 && extra == 0) {
          _status = 'Клетки на месте, а цвета — нет! Проверь блоки «Цвет» 🎨';
        } else if (missing > 0 && extra > 0) {
          _status = 'Почти! Не хватает $missing, лишних $extra.';
        } else if (missing > 0) {
          _status = 'Не хватает $missing клеток — добавь блоков!';
        } else if (extra > 0) {
          _status = 'Лишних $extra клеток — убери их из программы.';
        } else {
          _status = 'Почти! Проверь, каким цветом красит кисточка.';
        }
      });
    }
  }

  Widget _board() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _level.cols,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _level.cols * _level.rows,
          itemBuilder: (context, i) => _cell(i),
        ),
      ),
    );
  }

  Widget _cell(int index) {
    final targetColor = _level.colorTarget?[index];
    final inTarget = _level.target.contains(index);
    final painted = _painted.contains(index);
    final isCursor = _cursor == index && _running;
    Color color = Colors.grey.shade100;
    if (painted) {
      color = _colorful
          ? (kPixelColorValues[_colors[index]] ?? Colors.grey.shade400)
          : AppTheme.purple;
    } else if (targetColor != null) {
      color = (kPixelColorValues[targetColor] ?? AppTheme.sky)
          .withValues(alpha: 0.22);
    } else if (inTarget) {
      color = AppTheme.sky.withValues(alpha: 0.22);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isCursor
            ? Border.all(color: AppTheme.orange, width: 3)
            : null,
      ),
      child: Center(
        child: painted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : (isCursor
                ? Icon(Icons.brush_rounded, color: AppTheme.orange, size: 16)
                : null),
      ),
    );
  }

  /// Легенда красок уровня: какие цвета нужно использовать.
  Widget _colorLegend() {
    final used =
        (_level.colorTarget?.values.toSet() ?? const <int>{}).toList()..sort();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final value in used)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: kPixelColorValues[value] ?? AppTheme.sky,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                kPixelColorNames[value] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !_running && !_won;
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      HintBar(text: _level.hint),
                      if (_colorful) ...[
                        const SizedBox(height: 6),
                        _colorLegend(),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _board(),
                  )),
                ),
                if (_status.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Expanded(flex: 4, child: _programArea(canEdit)),
                _controls(canEdit),
                const SizedBox(height: 10),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: (3 - _failedRuns).clamp(1, 3),
                maxLevelIndex: _pixelLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _programArea(bool canEdit) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧱 Программа',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_program.isEmpty && !canEdit)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Здесь появится программа из блоков',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            BlockEditor(
              nodes: _program,
              commands: _colorful
                  ? [...kPixelBlocks, ...kPixelColorBlocks]
                  : kPixelBlocks,
              enabled: canEdit,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(bool canEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: KidButton(
              label: 'Запустить',
              icon: Icons.play_arrow_rounded,
              color: AppTheme.teal,
              expand: true,
              onPressed: canEdit && _program.isNotEmpty ? _run : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: KidButton(
              label: 'Очистить',
              icon: Icons.refresh_rounded,
              color: AppTheme.orange,
              expand: true,
              onPressed: canEdit && _program.isNotEmpty
                  ? () => setState(() {
                        _program.clear();
                        _painted = {};
                        _colors = {};
                        _cursor = 0;
                        _status = '';
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}