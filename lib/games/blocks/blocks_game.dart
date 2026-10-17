import 'dart:async';

import 'package:flutter/material.dart';

import '../../blocks/block_model.dart';
import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/block_editor.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import '../grid_board.dart';
import '../robot_maze/robot_maze_game.dart' show MazeLevel;

/// Команды робота в блочной игре.
const BlockCommandDef kRobotForward = BlockCommandDef(
  id: 'forward',
  icon: Icons.arrow_upward_rounded,
  label: 'Вперёд',
);
const BlockCommandDef kRobotLeft = BlockCommandDef(
  id: 'left',
  icon: Icons.turn_left_rounded,
  label: 'Налево',
);
const BlockCommandDef kRobotRight = BlockCommandDef(
  id: 'right',
  icon: Icons.turn_right_rounded,
  label: 'Направо',
);
const List<BlockCommandDef> kRobotBlocks = [
  kRobotForward,
  kRobotLeft,
  kRobotRight,
];

/// Клетки-стены удобно задавать парами (x, y).
Set<int> _walls(int cols, List<List<int>> cells) =>
    cells.map((c) => c[1] * cols + c[0]).toSet();

/// Уровни блочной игры. Геометрия переиспользует [MazeLevel] из «Робот-Лабиринта»,
/// но подсказки подталкивают собирать программу циклами.
final List<MazeLevel> _blockLevels = [
  const MazeLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 0,
    startY: 2,
    startDir: Direction.up,
    goalX: 0,
    goalY: 0,
    hint: 'Собери программу из блоков и доведи робота до флажка 🚩.',
  ),
  const MazeLevel(
    cols: 6,
    rows: 1,
    walls: {},
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 5,
    goalY: 0,
    hint: 'Коридор длинный — добавь блок «Повторить 5 раз».',
  ),
  const MazeLevel(
    cols: 5,
    rows: 5,
    walls: {},
    startX: 0,
    startY: 4,
    startDir: Direction.up,
    goalX: 4,
    goalY: 0,
    hint: 'Длинный путь вверх — цикл, а потом один поворот.',
  ),
  const MazeLevel(
    cols: 7,
    rows: 7,
    walls: {},
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 6,
    goalY: 6,
    hint: 'Два длинных отрезка — по блоку «Повторить» на каждый.',
  ),
  MazeLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [2, 0],
      [2, 1],
      [2, 2],
      [2, 3],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 4,
    goalY: 4,
    hint: 'Спустись вниз по краю циклом, потом поверни вправо.',
  ),
  MazeLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
    ]),
    startX: 4,
    startY: 4,
    startDir: Direction.up,
    goalX: 0,
    goalY: 0,
    hint: 'Стена поперёк: поверни вбок, пройди циклом и снова вверх.',
  ),
  MazeLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 3,
    goalY: 5,
    hint: 'Обойди стену снизу: цикл вниз, поворот, цикл вправо.',
  ),
  MazeLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'Справа стена — поверни вниз и иди вдоль неё.',
  ),
  MazeLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [2, 0],
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 5,
    goalY: 5,
    hint: 'Иди вниз до конца циклом, затем поверни и иди вправо.',
  ),
  MazeLevel(
    cols: 7,
    rows: 7,
    walls: _walls(7, [
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [0, 6],
      [1, 6],
      [2, 6],
      [3, 6],
      [4, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 6,
    goalY: 6,
    hint: 'Длинный маршрут: цикл вниз, поворот, цикл вправо, поворот и снова вниз.',
  ),
  MazeLevel(
    cols: 7,
    rows: 7,
    walls: _walls(7, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
    ]),
    startX: 6,
    startY: 6,
    startDir: Direction.up,
    goalX: 6,
    goalY: 0,
    hint: 'Длинная змейка: пройди вверх циклом, поверни вбок, снова вверх — и так до флажка.',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
    ]),
    startX: 7,
    startY: 7,
    startDir: Direction.up,
    goalX: 7,
    goalY: 0,
    hint: 'Четыре коридора. На каждый отрезок — блок «Повторить», между ними повороты.',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Вертикальная змейка: длинные циклы вниз и вверх, а между ними короткие шаги вбок.',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [7, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [8, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [7, 5],
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
      [6, 7],
      [7, 7],
      [8, 7],
    ]),
    startX: 0,
    startY: 8,
    startDir: Direction.up,
    goalX: 8,
    goalY: 0,
    hint: 'Пять длинных коридоров. Составь цикл для каждого отрезка и не забудь про четыре поворота.',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [1, 7],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [3, 8],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
      [5, 7],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
      [7, 7],
      [7, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 8,
    goalY: 8,
    hint: 'Самый длинный лабиринт: чередуй циклы вверх-вниз и короткие повороты вбок.',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 7,
    goalY: 7,
    hint: 'Три горизонтальные перегородки: после каждой проём на другом краю. Длинные отрезки — циклами!',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [1, 7],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [3, 8],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
      [5, 7],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
      [7, 7],
      [7, 8],
    ]),
    startX: 0,
    startY: 8,
    startDir: Direction.right,
    goalX: 8,
    goalY: 0,
    hint: 'Четыре высокие перегородки: змейка вверх-вниз. Восемь шагов по прямой — цикл из шести плюс два одиночных!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 2],
      [3, 4],
      [5, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 6,
    goalY: 7,
    hint: 'Лесенка из ступенек: два вперёд — поворот — два вперёд — поворот. Повтори узор три раза!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [6, 3],
      [6, 5],
      [2, 3],
      [2, 4],
      [2, 5],
      [2, 6],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'Стенка-замок с дверью справа. Обойди её по краю и войди в дверку — внутри ждёт флажок!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Три высокие перегородки: спускайся вниз, разворачивайся и поднимайся вверх. Длинные отрезки — циклами!',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
      [2, 5],
      [2, 6],
      [2, 7],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
      [4, 5],
      [4, 6],
      [4, 7],
      [6, 1],
      [6, 2],
      [6, 3],
      [6, 4],
      [6, 5],
      [6, 6],
      [6, 7],
    ]),
    startX: 0,
    startY: 8,
    startDir: Direction.right,
    goalX: 8,
    goalY: 0,
    hint: 'Вертикальная змейка через три перегородки: восемь шагов вверх или вниз — цикл из шести плюс два шага!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [4, 1],
      [4, 2],
      [4, 5],
      [4, 6],
      [2, 4],
      [3, 4],
      [5, 4],
      [6, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'От флажка в центре расходятся четыре стены-луча. Обойди поле по краю и войди в центр сверху!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 6],
      [3, 4],
      [5, 2],
      [6, 6],
    ]),
    startX: 0,
    startY: 7,
    startDir: Direction.right,
    goalX: 7,
    goalY: 0,
    hint: 'Ступеньки вверх: два вперёд, поворот, два вперёд, поворот. Узор повторяется три раза!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [0, 3],
      [0, 6],
      [7, 2],
      [3, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Пружина вниз-вправо: два вперёд, поворот, два вперёд, поворот. Узор три раза — и флажок в углу!',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 4,
    hint: 'Длинная S-труба: шесть вперёд, два вниз, шесть назад. Между отрезками — только повороты!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [2, 4],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [5, 3],
      [5, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 4,
    goalY: 4,
    hint: 'Замок с одной дверью слева. Подойди к дверке и войди внутрь к флажку!',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [7, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [8, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [7, 5],
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
      [6, 7],
      [7, 7],
      [8, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 8,
    hint: 'Четыре длинные перегородки: после каждой проём на другом краю. Отрезки по девять — цикл из шести плюс два шага!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 2],
      [3, 2],
      [5, 2],
      [2, 3],
      [5, 3],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 3,
    hint: 'Спираль-замок с дверью сверху: длинные отрезки по краю — циклами, а в дверку войди сверху вниз!',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 6],
      [3, 4],
      [5, 2],
      [0, 4],
    ]),
    startX: 0,
    startY: 7,
    startDir: Direction.up,
    goalX: 7,
    goalY: 0,
    hint: 'Пружина вверх-вправо: два вперёд, поворот, два вперёд, поворот. Узор три раза — и флажок в углу!',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [8, 2],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [3, 6],
      [6, 6],
      [6, 7],
      [6, 8],
      [3, 8],
      [4, 8],
      [5, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 5,
    goalY: 7,
    hint: 'Финал: длинная змейка через поле, потом замок с дверкой слева. Собери всё из циклов — и к флажку!',
  ),
  // 31: введение в «Мою функцию» — лесенка из маленьких ступенек.
  MazeLevel(
    cols: 7,
    rows: 7,
    walls: {},
    startX: 0,
    startY: 6,
    startDir: Direction.up,
    goalX: 6,
    goalY: 0,
    hint: 'Новая суперсила «Моя функция»! Собери в ней шаг-вверх-шаг-вправо, а потом вызови её шесть раз циклом!',
  ),
  // 32: пружина вниз-вправо — та же ступенька в другую сторону.
  MazeLevel(
    cols: 7,
    rows: 7,
    walls: {},
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 6,
    goalY: 6,
    hint: 'Ступенька-пружинка: в функции — шаг вниз и шаг вправо. Вызови её циклом шесть раз!',
  ),
  // 33: маленькая змейка — функция «пять шагов вперёд» вызывается три раза.
  MazeLevel(
    cols: 6,
    rows: 5,
    walls: _walls(6, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 5,
    goalY: 4,
    hint: 'Собери функцию «пять шагов вперёд» — она пройдёт каждый длинный ряд. Между рядами только поворот и два шага!',
  ),
  // 34: длинная лесенка — две «Повторить» с одинаковой функцией.
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: {},
    startX: 0,
    startY: 8,
    startDir: Direction.up,
    goalX: 8,
    goalY: 0,
    hint: 'Восемь ступенек вверх-вправо! Ступенька живёт в «Моей функции», а две «Повторить» доведут до верха.',
  ),
  // 35: змейка подлиннее — четыре вызова функции «пять шагов».
  MazeLevel(
    cols: 6,
    rows: 9,
    walls: _walls(6, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 8,
    hint: 'Функция «пять шагов вперёд» поможет пройти длинные ряды. Циклы для рядов уже не нужны — только повороты!',
  ),
  // 36: циклы отключены — только «Моя функция» (горизонтальная змейка 10×7).
  MazeLevel(
    cols: 10,
    rows: 7,
    walls: _walls(10, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [7, 1],
      [8, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [8, 3],
      [9, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [7, 5],
      [8, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 6,
    hint: 'Циклы тут отключены! Собери функцию «пять шагов вперёд» и зови её по нескольку раз в каждом ряду.',
  ),
  // 37: циклы отключены — вертикальная змейка 9×7, пять столбцов.
  MazeLevel(
    cols: 9,
    rows: 7,
    walls: _walls(9, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 8,
    goalY: 6,
    hint: 'Вертикальные ряды тоже любят функцию «пять шагов вперёд». Между рядами — развороты: поверни и шагни через проём!',
  ),
  // 38: циклы отключены — змейка 9×7, четыре ряда.
  MazeLevel(
    cols: 9,
    rows: 7,
    walls: _walls(9, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [7, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [8, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [7, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 6,
    hint: 'Ряд из восьми шагов = вызов функции «пять шагов» плюс три шага вперёд. Без циклов, зато надёжно!',
  ),
  // 39: циклы отключены — змейка 8×9, пять рядов длиной семь.
  MazeLevel(
    cols: 8,
    rows: 9,
    walls: _walls(8, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
      [6, 7],
      [7, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 7,
    goalY: 8,
    hint: 'Пять длинных рядов: вызов функции «пять шагов» и два шага вперёд на каждый ряд.',
  ),
  // 40: циклы отключены — змейка 7×9, пять рядов длиной шесть.
  MazeLevel(
    cols: 7,
    rows: 9,
    walls: _walls(7, [
      [0, 1],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [1, 3],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
      [6, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 6,
    goalY: 8,
    hint: 'Пять длинных рядов без циклов! Ряд из шести = вызов функции «пять шагов» плюс один шаг.',
  ),
  // 41: циклы отключены — большая вертикальная змейка 9×9, пять столбцов.
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [1, 7],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [3, 8],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
      [5, 7],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
      [7, 7],
      [7, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 8,
    goalY: 8,
    hint: 'Самая длинная вертикальная змейка без циклов: ряд из восьми шагов проходи функцией «пять шагов» плюс три шага.',
  ),
  // 42: крепость — обход правой рукой с условием «если впереди стена».
  MazeLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [1, 1],
      [2, 1],
      [3, 1],
      [1, 2],
      [3, 2],
      [1, 3],
      [2, 3],
      [3, 3],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 2,
    hint: 'Объезди крепость по правой руке: «Если впереди стена — направо, вперёд». Прямые участки — обычные шаги!',
  ),
  // 43: змейка через четыре высокие перегородки.
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 0],
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
      [2, 5],
      [2, 6],
      [2, 7],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
      [4, 5],
      [4, 6],
      [4, 7],
      [4, 8],
      [6, 0],
      [6, 1],
      [6, 2],
      [6, 3],
      [6, 4],
      [6, 5],
      [6, 6],
      [6, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 8,
    hint: 'Четыре высокие перегородки с проёмами то сверху, то снизу. Длинные участки — циклами, повороты — по одному!',
  ),
  // 44: змейка-обходчик — условие «обойди стену» в цикле.
  MazeLevel(
    cols: 9,
    rows: 5,
    walls: _walls(9, [
      [2, 0],
      [4, 1],
      [6, 2],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 3,
    hint: 'Умная змейка: «Если впереди стена — направо, вперёд, налево», а потом шаг вперёд. Один цикл — и змейка сама обойдёт все камни!',
  ),
  // 45: финал — большая змейка по четырём перегородкам.
  MazeLevel(
    cols: 10,
    rows: 6,
    walls: _walls(10, [
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [8, 2],
      [9, 2],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [7, 4],
      [8, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 5,
    hint: 'Финальный маршрут: четыре длинных ряда по краям перегородок. Собери из циклов — и к флажку!',
  ),
];

/// Уровни, где циклы отключены: робота ведёт только «Моя функция»
/// (индексы с нуля).
const Set<int> _noLoopLevelIndexes = {35, 36, 37, 38, 39, 40};

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<MazeLevel> get blockLevels => _blockLevels;

/// Игра «Программируй блоками»: программа из блоков с циклом и условием.
class BlocksGame extends StatefulWidget {
  const BlocksGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<BlocksGame> createState() => _BlocksGameState();
}

class _BlocksGameState extends State<BlocksGame> {
  late MazeLevel _level;
  final List<BlockNode> _program = [];
  FunctionDef? _function;

  int _x = 0;
  int _y = 0;
  Direction _dir = Direction.up;
  bool _running = false;
  bool _won = false;
  bool _crashed = false;
  int _steps = 0;
  int _failedRuns = 0;
  String _status = '';

  static const GameInfo _game = GameInfo(
    id: 'blocks',
    title: 'Программируй блоками',
    subtitle: '',
    emoji: '📦',
    levelCount: 45,
  );

  /// На этих уровнях циклы и условия отключены — только «Моя функция».
  bool get _noLoops => _noLoopLevelIndexes.contains(widget.levelIndex);

  @override
  void initState() {
    super.initState();
    _level = _blockLevels[widget.levelIndex % _blockLevels.length];
    _resetRobot();
  }

  void _resetRobot() {
    _x = _level.startX;
    _y = _level.startY;
    _dir = _level.startDir;
  }

  bool _isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= _level.cols || y >= _level.rows) return true;
    return _level.walls.contains(y * _level.cols + x);
  }

  bool _wallAhead() => _isBlocked(_x + _dir.dx, _y + _dir.dy);

  void _restart() {
    setState(() {
      _program.clear();
      _function = null;
      _failedRuns = 0;
      _won = false;
      _crashed = false;
      _running = false;
      _status = '';
      _resetRobot();
    });
  }

  Future<void> _run() async {
    if (_program.isEmpty || _running || _won) return;
    final error = _validateProgram();
    if (error != null) {
      setState(() {
        _status = error;
        _failedRuns++;
      });
      return;
    }
    setState(() {
      _running = true;
      _crashed = false;
      _steps = 0;
      _status = 'Робот выполняет программу…';
      _resetRobot();
    });
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await _exec(_program);
    if (!mounted) return;

    final reached = _x == _level.goalX && _y == _level.goalY;
    if (reached) {
      final stars = (3 - _failedRuns).clamp(1, 3);
      setState(() {
        _running = false;
        _won = true;
        _status = 'Ура! Робот дошёл до флажка! 🚩';
      });
      widget.onFinished(stars);
    } else {
      setState(() {
        _running = false;
        _failedRuns++;
        if (!_crashed) {
          _status = 'Робот остановился. Добавь блоков или проверь цикл!';
        }
      });
    }
  }

  /// Проверка «моей функции» перед запуском (лимиты 2–5 команд).
  String? _validateProgram() {
    final function = _function;
    if (function == null) return null;
    if (countFunctionCalls(_program, function) == 0) return null;
    final count = function.body.length;
    if (count < kFunctionMinCommands) {
      return 'Добавь в «Мою функцию» от 2 до 5 команд 🙂';
    }
    if (count > kFunctionMaxCommands) {
      return 'В «Моей функции» может быть не больше 5 команд 🙂';
    }
    return null;
  }

  /// Выполняет список блоков пошагово с анимацией.
  /// Возвращает false, если робот врезался или достигнут лимит шагов.
  Future<bool> _exec(List<BlockNode> nodes) async {
    for (final node in nodes) {
      if (!mounted) return false;
      if (_steps >= kBlockMaxSteps) {
        setState(() => _status = 'Программа очень длинная — упрости её 🙂');
        return false;
      }
      switch (node) {
        case CommandBlock():
          _steps++;
          if (!await _applyCommand(node.def)) return false;
          await Future.delayed(const Duration(milliseconds: 300));
        case RepeatBlock():
          for (var i = 0; i < node.times; i++) {
            if (!await _exec(node.body)) return false;
          }
        case IfBlock():
          if (_wallAhead()) {
            if (!await _exec(node.body)) return false;
          }
        case FunctionCallBlock():
          // Вызов разворачивается в команды «моей функции».
          if (!await _exec(node.function.body)) return false;
      }
    }
    return true;
  }

  Future<bool> _applyCommand(BlockCommandDef def) async {
    if (!mounted) return false;
    switch (def.id) {
      case 'left':
        setState(() => _dir = _dir.turnLeft);
      case 'right':
        setState(() => _dir = _dir.turnRight);
      case 'forward':
        final nx = _x + _dir.dx;
        final ny = _y + _dir.dy;
        if (_isBlocked(nx, ny)) {
          setState(() {
            _crashed = true;
            _status = 'Ой! Робот врезался в стену 🧱';
          });
          return false;
        }
        setState(() {
          _x = nx;
          _y = ny;
        });
    }
    return true;
  }

  Widget _robot() {
    final angle = switch (_dir) {
      Direction.up => 0.0,
      Direction.right => 1.5708,
      Direction.down => 3.1416,
      Direction.left => -1.5708,
    };
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.purple,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        child: Transform.rotate(
          angle: angle,
          child: const Icon(Icons.navigation_rounded, color: Colors.white),
        ),
      ),
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
                  child: HintBar(text: _level.hint),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridBoard(
                      cols: _level.cols,
                      rows: _level.rows,
                      walls: _level.walls,
                      sprites: [
                        BoardSprite(
                          id: 'goal',
                          x: _level.goalX,
                          y: _level.goalY,
                          child: const FittedBox(
                            child: Text('🚩', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        BoardSprite(id: 'robot', x: _x, y: _y, child: _robot()),
                      ],
                    ),
                  ),
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
                maxLevelIndex: _blockLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  /// Создать «мою функцию» (пока без вызовов — команды добавит ребёнок).
  void _createFunction() {
    setState(() {
      _function = FunctionDef(icon: '🅰️');
      _status = 'Собери команды внутри «Моей функции» — от 2 до 5 🙂';
    });
  }

  /// Удалить функцию вместе со всеми её вызовами.
  void _removeFunction() {
    final function = _function;
    if (function == null) return;
    setState(() {
      removeFunctionCalls(_program, function);
      _function = null;
      _status = '';
    });
  }

  Widget _functionArea(bool canEdit) {
    final function = _function;
    if (function == null) {
      if (!canEdit) return const SizedBox.shrink();
      return KidButton(
        label: 'Моя функция',
        icon: Icons.add_circle_rounded,
        color: AppTheme.teal,
        expand: true,
        onPressed: _createFunction,
      );
    }
    const icons = ['🅰️', '🚀', '⭐', '🔑', '🎁', '🎈'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${function.icon} Моя функция',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: _removeFunction,
                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                  color: Colors.grey,
                  tooltip: 'Удалить функцию',
                ),
            ],
          ),
          if (canEdit)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final icon in icons)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      _function = FunctionDef(icon: icon, body: function.body);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: icon == function.icon
                            ? AppTheme.teal.withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: icon == function.icon
                              ? AppTheme.teal
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            'Команд: ${function.body.length} из $kFunctionMaxCommands',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          BlockEditor(
            nodes: function.body,
            commands: kRobotBlocks,
            enabled: canEdit,
            onChanged: () => setState(() {}),
            simpleOnly: true,
            maxNodes: kFunctionMaxCommands,
          ),
        ],
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
            _functionArea(canEdit),
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
              commands: kRobotBlocks,
              conditionLabel: _noLoops ? null : 'Если впереди стена',
              enabled: canEdit,
              onChanged: () => setState(() {}),
              function: _function,
              canCallFunction: _function != null &&
                  countFunctionCalls(_program, _function!) < kFunctionMaxCalls,
              onCreateFunction: _function == null ? _createFunction : null,
              hideContainers: _noLoops,
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
                  ? () => setState(_program.clear)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
