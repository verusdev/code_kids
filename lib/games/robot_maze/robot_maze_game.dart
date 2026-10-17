import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import '../grid_board.dart';

/// Команда программы робота.
enum MazeCommand { forward, turnLeft, turnRight }

extension on MazeCommand {
  IconData get icon => switch (this) {
        MazeCommand.forward => Icons.arrow_upward_rounded,
        MazeCommand.turnLeft => Icons.turn_left_rounded,
        MazeCommand.turnRight => Icons.turn_right_rounded,
      };

  String get label => switch (this) {
        MazeCommand.forward => 'Вперёд',
        MazeCommand.turnLeft => 'Налево',
        MazeCommand.turnRight => 'Направо',
      };
}

/// Цвет ключа или двери: ключ открывает дверь того же цвета.
enum MazeColor { red, blue, yellow }

/// Название цвета по-русски — для мягких подсказок.
extension MazeColorName on MazeColor {
  String get title => switch (this) {
        MazeColor.red => 'красный',
        MazeColor.blue => 'синий',
        MazeColor.yellow => 'жёлтый',
      };
}

/// Ключ на клетке: робот подбирает его, наступив на эту клетку.
class MazeKey {
  const MazeKey(this.x, this.y, this.color);

  final int x;
  final int y;
  final MazeColor color;
}

/// Дверь на клетке: пройти можно только с ключом того же цвета.
class MazeDoor {
  const MazeDoor(this.x, this.y, this.color);

  final int x;
  final int y;
  final MazeColor color;
}

/// Пара телепортов: наступив на один, робот переносится на парный вихрь.
///
/// Клетки (ax, ay) и (bx, by) образуют пару с одинаковой меткой.
class MazeTeleport {
  const MazeTeleport(this.ax, this.ay, this.bx, this.by);

  final int ax;
  final int ay;
  final int bx;
  final int by;
}

/// Описание одного уровня «Робот-Лабиринт».
class MazeLevel {
  const MazeLevel({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.startDir,
    required this.goalX,
    required this.goalY,
    required this.hint,
    this.keys = const [],
    this.doors = const [],
    this.teleports = const [],
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final Direction startDir;
  final int goalX;
  final int goalY;
  final String hint;

  /// Ключи на поле (необязательно, по умолчанию нет ключей).
  final List<MazeKey> keys;

  /// Двери на поле (необязательно, по умолчанию нет дверей).
  final List<MazeDoor> doors;

  /// Пары телепортов (необязательно, по умолчанию нет телепортов).
  final List<MazeTeleport> teleports;
}

/// Клетки-стены удобно задавать парами (x, y).
Set<int> _walls(int cols, List<List<int>> cells) =>
    cells.map((c) => c[1] * cols + c[0]).toSet();

final List<MazeLevel> _mazeLevels = [
  const MazeLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 0,
    startY: 2,
    startDir: Direction.up,
    goalX: 0,
    goalY: 0,
    hint: 'Нажми «Вперёд» и отправь робота к флажку.',
  ),
  MazeLevel(
    cols: 3,
    rows: 3,
    walls: _walls(3, [
      [1, 1],
    ]),
    startX: 0,
    startY: 2,
    startDir: Direction.up,
    goalX: 2,
    goalY: 2,
    hint: 'Поверни робота налево или направо, чтобы он пошёл вбок.',
  ),
  MazeLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [1, 1],
      [2, 2],
    ]),
    startX: 0,
    startY: 3,
    startDir: Direction.up,
    goalX: 3,
    goalY: 0,
    hint: 'Сначала поднимись наверх, потом поверни и иди вправо.',
  ),
  MazeLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [2, 0],
      [2, 1],
      [2, 2],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 3,
    goalY: 3,
    hint: 'Стена мешает напрямую — обойди её снизу.',
  ),
  MazeLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 2],
      [2, 2],
      [3, 2],
    ]),
    startX: 0,
    startY: 4,
    startDir: Direction.up,
    goalX: 4,
    goalY: 0,
    hint: 'Иди вверх до самого верха, затем поверни направо.',
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
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 4,
    goalY: 4,
    hint: 'Спустись вниз, пройди вправо и снова поверни к флажку.',
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
    hint: 'Спустись вниз по левому краю, а потом поверни и иди вправо.',
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
    hint: 'Стена поперёк — обойди её слева: поверни в бок, потом снова вверх.',
  ),
  MazeLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 5,
    goalY: 5,
    hint: 'Иди вниз по самому краю, затем поверни направо и дойди до флажка.',
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
    hint: 'Спустись до середины, поверни направо, дойди до края и снова поверни вниз.',
  ),
  MazeLevel(
    cols: 7,
    rows: 7,
    walls: _walls(7, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
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
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 6,
    goalY: 6,
    hint: 'Змейка из стен: спустись вниз, потом вверх, снова вниз — и до флажка в углу.',
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
    startY: 7,
    startDir: Direction.right,
    goalX: 7,
    goalY: 0,
    hint: 'Робот смотрит вбок. Иди между стенами то вверх, то вниз — через весь лабиринт.',
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
    startY: 0,
    startDir: Direction.left,
    goalX: 0,
    goalY: 7,
    hint: 'Стены лежат поперёк: обходи их по краям слева и справа, спускаясь всё ниже.',
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
    hint: 'Большой лабиринт: длинные коридоры вверх-вниз между стенами, флажок в дальнем углу.',
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
    startX: 8,
    startY: 0,
    startDir: Direction.left,
    goalX: 0,
    goalY: 8,
    hint: 'Самый длинный путь: спускайся по длинным коридорам между стен, зигзагом к флажку.',
  ),
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 1],
      [3, 1],
      [5, 1],
      [2, 2],
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
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Цель спряталась в дальнем углу. Если увидишь домик с открытой дверкой — внутри пусто, лучше обойди его по краю.',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [1, 3],
      [7, 3],
      [1, 5],
      [7, 4],
      [7, 5],
      [1, 6],
      [2, 6],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
      [7, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'Вокруг флажка высокий забор-замок, вход только слева, в самом центре. Найди единственный проём!',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [8, 2],
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [2, 6],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
      [7, 6],
      [8, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 4,
    goalY: 8,
    hint: 'После каждой перегородки проём оказывается то справа, то слева — следи, с какой стороны можно пройти.',
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
      [4, 0],
      [4, 1],
      [4, 2],
      [4, 3],
      [4, 4],
      [4, 5],
      [4, 6],
      [6, 2],
      [6, 3],
      [6, 4],
      [6, 5],
      [6, 6],
      [6, 7],
      [6, 8],
    ]),
    startX: 0,
    startY: 8,
    startDir: Direction.up,
    goalX: 8,
    goalY: 0,
    hint: 'Три вертикальные стены: проход в каждой — на своей высоте. Иди зигзагом снизу вверх.',
  ),
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 2],
      [4, 2],
      [2, 3],
      [4, 3],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 2],
      [6, 2],
      [7, 2],
      [5, 3],
      [7, 3],
      [5, 4],
      [7, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 6,
    goalY: 3,
    hint: 'Два домика: в первом пусто, во втором — флажок. Дверки у них в разных местах!',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [2, 2],
      [3, 2],
      [4, 2],
      [7, 1],
      [7, 2],
      [7, 3],
      [2, 5],
      [3, 5],
      [5, 4],
      [5, 5],
      [5, 6],
      [7, 6],
      [8, 6],
      [2, 8],
      [3, 8],
      [4, 8],
      [6, 8],
      [7, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Между валунами всегда есть дорога — ищи самый короткий зигзаг к флажку.',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [0, 2],
      [2, 2],
      [4, 2],
      [6, 2],
      [8, 2],
      [1, 5],
      [3, 5],
      [5, 5],
      [7, 5],
      [9, 5],
      [0, 8],
      [2, 8],
      [4, 8],
      [6, 8],
      [8, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Столбики стоят через клетку: проход всегда есть, но поворотов наберётся много.',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
      [6, 7],
      [7, 7],
      [2, 3],
      [2, 5],
      [2, 6],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
      [4, 4],
      [5, 4],
      [6, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 5,
    goalY: 5,
    hint: 'Внутри большого квадрата спрятан флажок, вход в него один — слева. А внутри ещё и стенка-делитель, её надо обойти.',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [0, 2],
      [1, 2],
      [2, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [8, 2],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [7, 4],
      [8, 4],
      [9, 4],
      [0, 6],
      [1, 6],
      [2, 6],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
      [7, 6],
      [8, 6],
      [1, 8],
      [2, 8],
      [3, 8],
      [4, 8],
      [5, 8],
      [6, 8],
      [7, 8],
      [8, 8],
      [9, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 9,
    hint: 'Четыре длинные перегородки: после каждой проём оказывается на противоположном краю. Спускайся змейкой вниз.',
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
      [1, 3],
      [1, 7],
      [1, 8],
      [8, 3],
      [8, 4],
      [8, 5],
      [8, 6],
      [1, 8],
      [2, 8],
      [3, 8],
      [4, 8],
      [5, 8],
      [6, 8],
      [7, 8],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
      [3, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 5,
    hint: 'Два замка один внутри другого: у первого вход слева, у второго — справа. Ищи проёмы по очереди!',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [4, 1],
      [4, 2],
      [4, 3],
      [1, 4],
      [2, 4],
      [3, 4],
      [6, 4],
      [7, 4],
      [8, 4],
      [4, 6],
      [4, 7],
      [4, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'От флажка расходятся четыре стены-луча. Подбирайся к цели по диагонали между лучами.',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [1, 6],
      [1, 7],
      [1, 8],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [3, 8],
      [3, 9],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
      [5, 7],
      [5, 8],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
      [7, 6],
      [7, 7],
      [7, 8],
      [7, 9],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 9,
    goalY: 9,
    hint: 'Четыре высокие стены: у каждой проём то внизу, то вверху. Иди змейкой и не потеряй ритм!',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [2, 1],
      [4, 1],
      [2, 2],
      [4, 2],
      [2, 3],
      [3, 3],
      [4, 3],
      [6, 1],
      [7, 1],
      [8, 1],
      [6, 2],
      [6, 3],
      [7, 3],
      [8, 3],
      [2, 6],
      [3, 6],
      [4, 6],
      [2, 7],
      [4, 7],
      [2, 8],
      [4, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 3,
    goalY: 7,
    hint: 'Два домика-ловушки пустые, а в третьем, нижнем, — флажок. Дверки у всех в разных местах!',
  ),
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [4, 1],
      [4, 4],
      [4, 7],
      [5, 2],
      [5, 5],
      [5, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Поперёк поля — стена-решётка с зубцами. Проходы есть, но каждый зубец нужно обойти сверху или снизу.',
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
      [0, 4],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [7, 4],
      [3, 5],
      [3, 6],
      [3, 7],
      [3, 8],
      [6, 6],
      [7, 6],
      [8, 6],
      [6, 7],
      [8, 7],
      [6, 8],
      [8, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 7,
    goalY: 7,
    hint: 'Финальный маршрут: вниз через две перегородки, потом в обход по низу — и в домик снизу, где ждёт флажок. Не спеши!',
  ),
  // === Новые уровни 31–45: ключи, двери и телепорты. ===
  // 31: первый ключ и первая дверь (8×8, змейка из трёх перегородок).
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
      [0, 6], [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 7,
    goalY: 7,
    hint: 'Появился ключ 🔑 и дверь 🚪! Дверь открывается ключом того же цвета — сначала возьми ключ.',
    keys: const [MazeKey(4, 0, MazeColor.red)],
    doors: const [MazeDoor(7, 2, MazeColor.red)],
  ),
  // 32: синий ключ и синяя дверь (8×8, вертикальная змейка).
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 0], [2, 1], [2, 2], [2, 3], [2, 4], [2, 5], [2, 6],
      [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7],
      [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Синий ключ 🔵 откроет только синюю дверь 🚪. Спустись вниз, найди ключ и поднимись к двери.',
    keys: [const MazeKey(3, 4, MazeColor.blue)],
    doors: [const MazeDoor(4, 0, MazeColor.blue)],
  ),
  // 33: первый телепорт — короткий путь через стену (8×8).
  MazeLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5],
      [4, 1], [4, 2],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 7,
    goalY: 7,
    hint: 'Видишь вихрь 🌀? Наступи на него — и робот мгновенно перенесётся к такому же вихрю. Это короткая дорога!',
    teleports: [const MazeTeleport(1, 1, 1, 4)],
  ),
  // 34: два цвета — красный и синий (9×9).
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5],
      [0, 7], [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7], [7, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 8,
    hint: 'Два ключа — два цвета: красный 🔴 и синий 🔵. Каждый открывает дверь своего цвета. Не перепутай!',
    keys: [const MazeKey(4, 0, MazeColor.red), const MazeKey(5, 3, MazeColor.blue)],
    doors: [const MazeDoor(8, 2, MazeColor.red), const MazeDoor(0, 5, MazeColor.blue)],
  ),
  // 35: цепочка «ключ → дверь → телепорт» (9×9).
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [8, 4],
      [0, 6], [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 8,
    hint: 'Три подсказки подряд: сначала ключ 🔑, потом дверь 🚪, а потом вихрь 🌀 перенесёт робота вниз.',
    keys: [const MazeKey(4, 0, MazeColor.red)],
    doors: [const MazeDoor(8, 2, MazeColor.red)],
    teleports: [const MazeTeleport(2, 3, 2, 5)],
  ),
  // 35→36: тупики и синий ключ (9×9).
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2],
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5],
      [4, 0], [4, 1],
      [6, 6], [6, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 8,
    goalY: 8,
    hint: 'Не все пути ведут к цели — в тупиках придётся повернуть назад. И не забудь про синий ключ 🔵!',
    keys: [const MazeKey(6, 4, MazeColor.blue)],
    doors: [const MazeDoor(8, 5, MazeColor.blue)],
  ),
  // 37: пара телепортов через весь лабиринт (9×9).
  MazeLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 1], [2, 2], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7],
      [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6],
      [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6], [6, 7],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 8,
    goalY: 8,
    hint: 'Вихри 🌀 соединены парами. Один прыжок — и робот уже в другом конце лабиринта, внизу справа!',
    teleports: [const MazeTeleport(1, 4, 7, 4)],
  ),
  // 38: жёлтый ключ и жёлтая дверь (10×10, длинная змейка).
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [8, 4], [9, 4],
      [0, 6], [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6], [8, 6],
      [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], [6, 8], [7, 8], [8, 8], [9, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Жёлтый ключ 🔑 открывает жёлтую дверь 🚪. Длинная змейка — не потеряй ключ по дороге!',
    keys: [const MazeKey(5, 0, MazeColor.yellow)],
    doors: [const MazeDoor(9, 2, MazeColor.yellow)],
  ),
  // 39: два телепорта (10×10).
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3],
      [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6], [8, 6], [9, 6],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Два вихря 🌀! Запомни, куда ведёт каждый из них, — и выбери, какой поможет быстрее.',
    teleports: [
      const MazeTeleport(2, 1, 7, 4),
      const MazeTeleport(4, 2, 2, 7),
    ],
  ),
  // 40: ключи двух цветов, две двери и телепорт (10×10).
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5],
      [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], [6, 8], [7, 8], [8, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 9,
    goalY: 9,
    hint: 'Красный 🔴 и синий 🔵 ключи открывают двери своих цветов, а вихрь 🌀 помогает добраться быстрее.',
    keys: [const MazeKey(4, 0, MazeColor.red), const MazeKey(7, 3, MazeColor.blue)],
    doors: [const MazeDoor(9, 2, MazeColor.red), const MazeDoor(0, 5, MazeColor.blue)],
    teleports: [const MazeTeleport(2, 6, 7, 6)],
  ),
  // 41: замок с одной дверью (10×10).
  MazeLevel(
    cols: 10,
    rows: 10,
    walls: _walls(10, [
      [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
      [2, 7], [3, 7], [4, 7], [5, 7], [6, 7], [7, 7],
      [2, 3], [2, 5], [2, 6],
      [7, 3], [7, 4], [7, 5], [7, 6],
      [5, 4], [5, 5],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 4,
    goalY: 4,
    hint: 'Это замок 🏰! Вход только один — слева, и он закрыт жёлтой дверью 🚪. Найди жёлтый ключ 🔑!',
    keys: [const MazeKey(5, 0, MazeColor.yellow)],
    doors: [const MazeDoor(2, 4, MazeColor.yellow)],
  ),
  // 42: большая змейка и красный ключ (11×11).
  MazeLevel(
    cols: 11,
    rows: 11,
    walls: _walls(11, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2], [9, 2],
      [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [8, 4], [9, 4], [10, 4],
      [0, 6], [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6], [8, 6], [9, 6],
      [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], [6, 8], [7, 8], [8, 8], [9, 8], [10, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 10,
    goalY: 10,
    hint: 'Огромная змейка! Красный ключ 🔴 ждёт в самом начале пути, а дверь 🚪 — справа наверху.',
    keys: [const MazeKey(5, 0, MazeColor.red)],
    doors: [const MazeDoor(10, 2, MazeColor.red)],
  ),
  // 43: лабиринт с телепортами (11×11).
  MazeLevel(
    cols: 11,
    rows: 11,
    walls: _walls(11, [
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3], [9, 3],
      [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6], [8, 6], [9, 6], [10, 6],
      [0, 9], [1, 9], [2, 9], [3, 9], [4, 9], [5, 9], [6, 9], [7, 9], [8, 9], [9, 9],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 10,
    goalY: 10,
    hint: 'Лабиринт с вихрями 🌀. Найди все пары телепортов и выбери самый короткий путь к флажку.',
    teleports: [
      const MazeTeleport(2, 2, 8, 4),
      const MazeTeleport(5, 7, 3, 10),
    ],
  ),
  // 44: два цвета и телепорт (11×11).
  MazeLevel(
    cols: 11,
    rows: 11,
    walls: _walls(11, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2], [9, 2],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5], [10, 5],
      [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], [6, 8], [7, 8], [8, 8], [9, 8],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 10,
    goalY: 10,
    hint: 'Красный 🔴 и синий 🔵 ключи, две двери 🚪 и вихрь 🌀 — собери всё по порядку!',
    keys: [const MazeKey(4, 0, MazeColor.red), const MazeKey(6, 3, MazeColor.blue)],
    doors: [const MazeDoor(10, 2, MazeColor.red), const MazeDoor(0, 5, MazeColor.blue)],
    teleports: [const MazeTeleport(2, 9, 8, 9)],
  ),
  // 45: финал — ключ, дверь и телепорт вместе (11×11).
  MazeLevel(
    cols: 11,
    rows: 11,
    walls: _walls(11, [
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2], [9, 2],
      [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5], [10, 5],
      [0, 7], [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7], [7, 7], [8, 7], [9, 7],
      [1, 9], [2, 9], [3, 9], [4, 9], [5, 9], [6, 9], [7, 9], [8, 9], [9, 9], [10, 9],
      [4, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 10,
    goalY: 10,
    hint: 'Финальный лабиринт! Сначала ключ 🔑, потом дверь 🚪, а вихрь 🌀 перенесёт робота вниз. Ты справишься!',
    keys: [const MazeKey(5, 0, MazeColor.yellow)],
    doors: [const MazeDoor(10, 2, MazeColor.yellow)],
    teleports: [const MazeTeleport(3, 3, 7, 8)],
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<MazeLevel> get mazeLevels => _mazeLevels;

/// Игра «Робот-Лабиринт»: ребёнок составляет программу из команд, робот её
/// выполняет. Учит последовательности и поворотам.
class RobotMazeGame extends StatefulWidget {
  const RobotMazeGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<RobotMazeGame> createState() => _RobotMazeGameState();
}

class _RobotMazeGameState extends State<RobotMazeGame> {
  late MazeLevel _level;
  final List<MazeCommand> _program = [];

  int _x = 0;
  int _y = 0;
  Direction _dir = Direction.up;
  bool _running = false;
  bool _won = false;
  int _failedRuns = 0;
  String _status = '';

  /// Индексы собранных ключей на текущем запуске.
  final Set<int> _takenKeys = {};

  /// Клетка-вихрь, в которую робот только что перенёсся и которая
  /// не сработает повторно до следующего командного шага.
  int _teleportCooldown = -1;

  /// Кратковременная вспышка при телепортации.
  bool _flash = false;

  static const GameInfo _game = GameInfo(
    id: 'maze',
    title: 'Робот-Лабиринт',
    subtitle: '',
    emoji: '🤖',
    levelCount: 45,
  );

  @override
  void initState() {
    super.initState();
    _level = _mazeLevels[widget.levelIndex % _mazeLevels.length];
    _resetRobot();
  }

  void _resetRobot() {
    _x = _level.startX;
    _y = _level.startY;
    _dir = _level.startDir;
    _takenKeys.clear();
    _teleportCooldown = -1;
    _flash = false;
  }

  bool _isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= _level.cols || y >= _level.rows) return true;
    return _level.walls.contains(y * _level.cols + x);
  }

  /// Есть ли у робота ключ указанного цвета.
  bool _hasKey(MazeColor color) {
    for (final i in _takenKeys) {
      if (_level.keys[i].color == color) return true;
    }
    return false;
  }

  /// Индекс ключа в клетке или −1, если ключа нет.
  int _keyIndexAt(int x, int y) {
    for (var i = 0; i < _level.keys.length; i++) {
      final k = _level.keys[i];
      if (k.x == x && k.y == y) return i;
    }
    return -1;
  }

  /// Дверь в клетке или null.
  MazeDoor? _doorAt(int x, int y) {
    for (final d in _level.doors) {
      if (d.x == x && d.y == y) return d;
    }
    return null;
  }

  /// Клетка парного телепорта или −1.
  int _teleportPartner(int x, int y) {
    for (final t in _level.teleports) {
      if (t.ax == x && t.ay == y) return t.by * _level.cols + t.bx;
      if (t.bx == x && t.by == y) return t.ay * _level.cols + t.ax;
    }
    return -1;
  }

  void _restart() {
    setState(() {
      _program.clear();
      _failedRuns = 0;
      _won = false;
      _status = '';
      _running = false;
      _resetRobot();
    });
  }

  /// Короткая вспышка поверх поля при переносе робота.
  void _flashOnce() {
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  Future<void> _run() async {
    if (_program.isEmpty || _running || _won) return;
    setState(() {
      _running = true;
      _status = 'Робот выполняет программу…';
      _resetRobot();
    });
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    bool crashed = false;
    for (final cmd in _program) {
      if (!mounted) return;
      // Новый командный шаг — вихри снова активны.
      _teleportCooldown = -1;
      switch (cmd) {
        case MazeCommand.turnLeft:
          setState(() => _dir = _dir.turnLeft);
        case MazeCommand.turnRight:
          setState(() => _dir = _dir.turnRight);
        case MazeCommand.forward:
          final nx = _x + _dir.dx;
          final ny = _y + _dir.dy;
          if (_isBlocked(nx, ny)) {
            setState(() {
              _status = 'Ой! Робот врезался в стену 🧱';
            });
            crashed = true;
          } else {
            final door = _doorAt(nx, ny);
            if (door != null && !_hasKey(door.color)) {
              setState(() {
                _status = 'Сначала возьми ключ 🔑! Нужен '
                    '${door.color.title} ключ.';
              });
              crashed = true;
            } else {
              // Находим парный вихрь, если робот наступает на телепорт.
              final partner = _teleportPartner(nx, ny);
              final cell = ny * _level.cols + nx;
              final dest =
                  (partner >= 0 && cell != _teleportCooldown) ? partner : -1;
              final destX = dest >= 0 ? dest % _level.cols : nx;
              final destY = dest >= 0 ? dest ~/ _level.cols : ny;
              final keyHere = _keyIndexAt(nx, ny);
              final keyThere = dest >= 0 ? _keyIndexAt(destX, destY) : -1;
              setState(() {
                if (keyHere >= 0) _takenKeys.add(keyHere);
                if (keyThere >= 0) _takenKeys.add(keyThere);
                _x = destX;
                _y = destY;
                if (dest >= 0) {
                  _teleportCooldown = dest;
                  _status = 'Вжух! Робот перенёсся по вихрю 🌀';
                } else if (keyHere >= 0) {
                  _status = 'Робот взял ключ 🔑 — теперь он может открыть дверь!';
                }
              });
              if (dest >= 0) _flashOnce();
            }
          }
      }
      if (crashed) break;
      await Future.delayed(const Duration(milliseconds: 330));
      if (!mounted) return;
    }

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
        if (!crashed) {
          _status = 'Робот остановился. Добавь ещё команд!';
        }
      });
    }
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

  /// Цвет вещи по цвету ключа или двери.
  Color _mazeColor(MazeColor c) => switch (c) {
        MazeColor.red => const Color(0xFFE53935),
        MazeColor.blue => const Color(0xFF1E88E5),
        MazeColor.yellow => const Color(0xFFFBC02D),
      };

  /// Цвета пар телепортов (пары различаются по цвету вихря).
  static const List<Color> _teleportColors = [
    AppTheme.teal,
    AppTheme.orange,
    AppTheme.sky,
    AppTheme.pink,
  ];

  /// Значок ключа нужного цвета.
  Widget _keyView(MazeColor c) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _mazeColor(c),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Text('🔑', style: TextStyle(fontSize: 20)),
      );

  /// Значок двери: закрытая — 🚪, открытая (есть ключ) — 🔓.
  Widget _doorView(MazeColor c, {required bool open}) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _mazeColor(c).withValues(alpha: open ? 0.35 : 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(open ? '🔓' : '🚪', style: const TextStyle(fontSize: 20)),
      );

  /// Значок вихря; пары одного телепорта окрашены одинаково.
  Widget _teleportView(int index) {
    final color = _teleportColors[index % _teleportColors.length];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      child: const Text('🌀', style: TextStyle(fontSize: 20)),
    );
  }

  /// Предметы на поле: двери, несобранные ключи и вихри.
  List<BoardProp> _props() {
    final props = <BoardProp>[];
    for (var i = 0; i < _level.doors.length; i++) {
      final d = _level.doors[i];
      props.add(BoardProp(
        id: 'door$i',
        x: d.x,
        y: d.y,
        child: _doorView(d.color, open: _hasKey(d.color)),
      ));
    }
    for (var i = 0; i < _level.keys.length; i++) {
      if (_takenKeys.contains(i)) continue;
      final k = _level.keys[i];
      props.add(BoardProp(id: 'key$i', x: k.x, y: k.y, child: _keyView(k.color)));
    }
    for (var i = 0; i < _level.teleports.length; i++) {
      final t = _level.teleports[i];
      props.add(BoardProp(
          id: 'tp${i}a', x: t.ax, y: t.ay, child: _teleportView(i)));
      props.add(BoardProp(
          id: 'tp${i}b', x: t.bx, y: t.by, child: _teleportView(i)));
    }
    return props;
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridBoard(
                      cols: _level.cols,
                      rows: _level.rows,
                      walls: _level.walls,
                      props: _props(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                _programBar(),
                _controls(canEdit),
                const SizedBox(height: 12),
              ],
            ),
            // Вспышка при телепортации робота.
            if (_flash)
              IgnorePointer(
                child: Container(
                  color: AppTheme.purple.withValues(alpha: 0.28),
                ),
              ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: (3 - _failedRuns).clamp(1, 3),
                maxLevelIndex: _mazeLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _programBar() {
    return Container(
      height: 62,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
      ),
      child: _program.isEmpty
          ? const Center(
              child: Text(
                'Здесь появится программа робота',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _program.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                return Container(
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      Icon(_program[i].icon,
                          size: 20, color: AppTheme.purple),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _controls(bool canEdit) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final cmd in MazeCommand.values)
              KidButton(
                label: cmd.label,
                icon: cmd.icon,
                color: AppTheme.purple,
                onPressed: canEdit
                    ? () => setState(() => _program.add(cmd))
                    : null,
              ),
            KidButton(
              label: 'Убрать',
              icon: Icons.backspace_rounded,
              color: AppTheme.pink,
              onPressed: canEdit && _program.isNotEmpty
                  ? () => setState(() => _program.removeLast())
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
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
        ),
      ],
    );
  }
}
