// Расширенная проверка игры «Программируй блоками» (45 уровней).
//
// Каждый уровень проверяется на «решаемость» программой, допустимой в
// редакторе блоков: глубина контейнеров ≤ 2, блоков ≤ 40, шагов ≤ 300,
// «повторить» 2..6. Для уровней 36–41 (индексы 35–40), где циклы в игре
// отключены, решение обязано использовать «Мою функцию» (тело 2–5 простых
// команд, не больше 5 вызовов, без циклов и условий).
//
// Алгоритмы — порт эталонной утилиты tool/blocks_pixel_ext_check.dart
// (файл только для чтения), но работают напрямую с реальными классами
// MazeLevel/BlockNode из lib, а не с разбором исходников.
import 'dart:collection';

import 'package:code_kids/blocks/block_model.dart';
import 'package:code_kids/games/blocks/blocks_game.dart';
import 'package:code_kids/games/robot_maze/robot_maze_game.dart' show MazeLevel;
import 'package:flutter_test/flutter_test.dart';

// Смещения по направлениям (совпадают с Direction: up, right, down, left).
const List<int> _dx = [0, 1, 0, -1];
const List<int> _dy = [-1, 0, 1, 0];

/// Уровни, где циклы отключены (индексы с нуля). Дублирует приватную
/// константу `_noLoopLevelIndexes` из blocks_game.dart.
const Set<int> _noLoopIndexes = {35, 36, 37, 38, 39, 40};

bool _blocked(MazeLevel level, int x, int y) =>
    x < 0 ||
    y < 0 ||
    x >= level.cols ||
    y >= level.rows ||
    level.walls.contains(y * level.cols + x);

/// Достижима ли цель; возвращает длину кратчайшего пути в «шагах».
int? mazeReachable(MazeLevel level) {
  final startD = level.startDir.index;
  final visited = <String>{'${level.startX},${level.startY},$startD'};
  final queue = Queue<List<int>>()
    ..add([level.startX, level.startY, startD, 0]);
  while (queue.isNotEmpty) {
    final s = queue.removeFirst();
    final x = s[0], y = s[1], d = s[2], steps = s[3];
    if (x == level.goalX && y == level.goalY) return steps;
    for (final nd in [(d + 1) % 4, (d + 3) % 4]) {
      if (visited.add('$x,$y,$nd')) queue.add([x, y, nd, steps]);
    }
    final nx = x + _dx[d];
    final ny = y + _dy[d];
    if (!_blocked(level, nx, ny) && visited.add('$nx,$ny,$d')) {
      queue.add([nx, ny, d, steps + 1]);
    }
  }
  return null;
}

/// Кратчайшая последовательность команд ['F' | 'L' | 'R'] до цели.
List<String>? mazeCommands(MazeLevel level) {
  final startKey = '${level.startX},${level.startY},${level.startDir.index}';
  final prev = <String, String>{startKey: ''};
  final queue = Queue<List<int>>()
    ..add([level.startX, level.startY, level.startDir.index]);
  String? goalKey;
  while (queue.isNotEmpty) {
    final s = queue.removeFirst();
    final x = s[0], y = s[1], d = s[2];
    final key = '$x,$y,$d';
    if (x == level.goalX && y == level.goalY) {
      goalKey = key;
      break;
    }
    for (final nd in [(d + 1) % 4, (d + 3) % 4]) {
      final nk = '$x,$y,$nd';
      if (!prev.containsKey(nk)) {
        prev[nk] = key;
        queue.add([x, y, nd]);
      }
    }
    final nx = x + _dx[d];
    final ny = y + _dy[d];
    final nk = '$nx,$ny,$d';
    if (!_blocked(level, nx, ny) && !prev.containsKey(nk)) {
      prev[nk] = key;
      queue.add([nx, ny, d]);
    }
  }
  if (goalKey == null) return null;

  // Восстанавливаем цепочку состояний.
  final states = <String>[];
  var cur = goalKey;
  while (cur.isNotEmpty) {
    states.add(cur);
    cur = prev[cur]!;
  }
  final ordered = states.reversed.toList();
  final commands = <String>[];
  var d = level.startDir.index;
  var px = level.startX;
  var py = level.startY;
  for (var i = 1; i < ordered.length; i++) {
    final parts = ordered[i].split(',');
    final nx = int.parse(parts[0]);
    final ny = int.parse(parts[1]);
    final nd = int.parse(parts[2]);
    if (nx == px && ny == py) {
      // Ребро-поворот: позиция не меняется, меняется направление.
      final delta = (nd - d) % 4;
      if (delta == 1) {
        commands.add('R');
      } else if (delta == 3) {
        commands.add('L');
      } else if (delta == 2) {
        commands..add('R')..add('R');
      }
    } else {
      commands.add('F');
    }
    d = nd;
    px = nx;
    py = ny;
  }
  return commands;
}

/// Программа-решение с циклом на длинных отрезках «вперёд».
List<BlockNode> flatSolution(List<String> commands) {
  final nodes = <BlockNode>[];
  var i = 0;
  while (i < commands.length) {
    if (commands[i] == 'F') {
      var run = 0;
      while (i + run < commands.length && commands[i + run] == 'F') {
        run++;
      }
      var left = run;
      while (left > 0) {
        if (left == 1) {
          nodes.add(CommandBlock(kRobotForward));
          left -= 1;
        } else {
          final take = left >= kBlockMaxTimes ? kBlockMaxTimes : left;
          nodes.add(RepeatBlock(
            times: take,
            body: [CommandBlock(kRobotForward)],
          ));
          left -= take;
        }
      }
      i += run;
    } else {
      nodes.add(CommandBlock(commands[i] == 'R' ? kRobotRight : kRobotLeft));
      i++;
    }
  }
  return nodes;
}

/// Программа «без циклов»: длинные отрезки «вперёд» проходятся вызовами
/// «моей функции» (тело — [funcLen] шагов вперёд), остаток — одиночными шагами.
({List<BlockNode> program, FunctionDef function}) callSolution(
  List<String> commands, {
  int maxCalls = kFunctionMaxCalls,
}) {
  final totalForwards = commands.where((c) => c == 'F').length;
  final funcLen = totalForwards >= kFunctionMaxCommands
      ? kFunctionMaxCommands
      : (totalForwards >= kFunctionMinCommands
          ? totalForwards
          : kFunctionMinCommands);
  final function = FunctionDef(
    icon: '🅰️',
    body: [
      for (var i = 0; i < funcLen; i++) CommandBlock(kRobotForward),
    ],
  );
  final nodes = <BlockNode>[];
  var budget = maxCalls;
  var i = 0;
  while (i < commands.length) {
    if (commands[i] == 'F') {
      var run = 0;
      while (i + run < commands.length && commands[i + run] == 'F') {
        run++;
      }
      var left = run;
      while (left >= funcLen && budget > 0) {
        nodes.add(FunctionCallBlock(function));
        left -= funcLen;
        budget--;
      }
      while (left > 0) {
        nodes.add(CommandBlock(kRobotForward));
        left--;
      }
      i += run;
    } else {
      nodes.add(CommandBlock(commands[i] == 'R' ? kRobotRight : kRobotLeft));
      i++;
    }
  }
  return (program: nodes, function: function);
}

/// Результат прогона программы.
class Sim {
  Sim({
    required this.x,
    required this.y,
    required this.crashed,
    required this.steps,
  });

  final int x;
  final int y;
  final bool crashed;
  final int steps;
}

/// Выполняет программу так же, как `_exec` в blocks_game.dart:
/// «Вперёд» в стену — авария, условие — «если впереди стена», вызов функции
/// разворачивается в её команды.
Sim simulateBlocks(
  List<BlockNode> program,
  MazeLevel level, {
  int maxSteps = kBlockMaxSteps,
}) {
  var x = level.startX;
  var y = level.startY;
  var dir = level.startDir;
  var steps = 0;
  var crashed = false;

  void run(List<BlockNode> nodes) {
    for (final node in nodes) {
      if (crashed || steps >= maxSteps) return;
      switch (node) {
        case CommandBlock():
          steps++;
          switch (node.def.id) {
            case 'left':
              dir = dir.turnLeft;
            case 'right':
              dir = dir.turnRight;
            case 'forward':
              final nx = x + dir.dx;
              final ny = y + dir.dy;
              if (_blocked(level, nx, ny)) {
                crashed = true;
              } else {
                x = nx;
                y = ny;
              }
          }
        case RepeatBlock():
          for (var i = 0; i < node.times && !crashed && steps < maxSteps; i++) {
            run(node.body);
          }
        case IfBlock():
          if (_blocked(level, x + dir.dx, y + dir.dy)) run(node.body);
        case FunctionCallBlock():
          run(node.function.body);
      }
    }
  }

  run(program);
  return Sim(x: x, y: y, crashed: crashed, steps: steps);
}

int _depth(List<BlockNode> nodes, int depth) {
  var best = depth;
  for (final node in nodes) {
    if (node is RepeatBlock) {
      final d = _depth(node.body, depth + 1);
      if (d > best) best = d;
    } else if (node is IfBlock) {
      final d = _depth(node.body, depth + 1);
      if (d > best) best = d;
    }
  }
  return best;
}

void _expectTimesWithin(List<BlockNode> nodes, {required String reason}) {
  for (final node in nodes) {
    if (node is RepeatBlock) {
      expect(node.times, inInclusiveRange(kBlockMinTimes, kBlockMaxTimes),
          reason: reason);
      _expectTimesWithin(node.body, reason: reason);
    } else if (node is IfBlock) {
      _expectTimesWithin(node.body, reason: reason);
    }
  }
}

void main() {
  test('в блочной игре 45 уровней', () {
    expect(blockLevels.length, 45);
  });

  test('структура уровней корректна и каждый решаем в лимитах редактора', () {
    for (var i = 0; i < blockLevels.length; i++) {
      final level = blockLevels[i];
      final n = i + 1;

      expect(
        level.walls.contains(level.startY * level.cols + level.startX),
        isFalse,
        reason: 'уровень $n: робот стоит на стене',
      );
      expect(
        level.walls.contains(level.goalY * level.cols + level.goalX),
        isFalse,
        reason: 'уровень $n: флажок стоит на стене',
      );
      expect(mazeReachable(level), isNotNull,
          reason: 'уровень $n не проходим');

      final commands = mazeCommands(level);
      expect(commands, isNotNull, reason: 'уровень $n: нет пути до цели');

      final noLoop = _noLoopIndexes.contains(i);
      final List<BlockNode> program;
      if (noLoop) {
        program = callSolution(commands!).program;
      } else {
        program = flatSolution(commands!);
      }

      // Лимиты редактора блоков.
      expect(countBlocks(program), lessThanOrEqualTo(kBlockMaxTotal),
          reason: 'уровень $n: блоков больше $kBlockMaxTotal');
      _expectTimesWithin(program, reason: 'уровень $n: «повторить» вне 2..6');
      expect(_depth(program, 0), lessThanOrEqualTo(2),
          reason: 'уровень $n: глубина контейнеров больше 2');

      final sim = simulateBlocks(program, level);
      expect(sim.crashed, isFalse, reason: 'уровень $n: решение врезается');
      expect(
        sim.x == level.goalX && sim.y == level.goalY,
        isTrue,
        reason: 'уровень $n: решение не доходит до флажка '
            '(${sim.x},${sim.y}) ≠ (${level.goalX},${level.goalY})',
      );
      expect(sim.steps, lessThanOrEqualTo(kBlockMaxSteps),
          reason: 'уровень $n: шагов больше $kBlockMaxSteps');
    }
  });

  test('уровни 36–41 (циклы выключены) решаются «Моей функцией»', () {
    for (final i in _noLoopIndexes) {
      final level = blockLevels[i];
      final n = i + 1;

      final commands = mazeCommands(level);
      expect(commands, isNotNull, reason: 'уровень $n');
      final built = callSolution(commands!);
      final program = built.program;
      final function = built.function;

      expect(
        function.body.length,
        inInclusiveRange(kFunctionMinCommands, kFunctionMaxCommands),
        reason: 'уровень $n: тело функции вне 2..5 команд',
      );
      expect(function.body.every((c) => c is CommandBlock), isTrue,
          reason: 'уровень $n: в теле функции есть не-команда');

      final calls = countFunctionCalls(program, function);
      expect(calls, greaterThanOrEqualTo(1),
          reason: 'уровень $n: нет ни одного вызова «моей функции»');
      expect(calls, lessThanOrEqualTo(kFunctionMaxCalls),
          reason: 'уровень $n: вызовов больше $kFunctionMaxCalls');

      // На бесцикловых уровнях циклы и условия запрещены.
      expect(
        program.any((node) => node is RepeatBlock || node is IfBlock),
        isFalse,
        reason: 'уровень $n: на бесцикловом уровне есть цикл или условие',
      );
      _expectTimesWithin(function.body,
          reason: 'уровень $n: «повторить» в функции вне 2..6');

      expect(countBlocks(program), lessThanOrEqualTo(kBlockMaxTotal),
          reason: 'уровень $n: блоков больше $kBlockMaxTotal');

      final sim = simulateBlocks(program, level);
      expect(sim.crashed, isFalse, reason: 'уровень $n: решение врезается');
      expect(
        sim.x == level.goalX && sim.y == level.goalY,
        isTrue,
        reason: 'уровень $n: решение не доходит до флажка',
      );
    }
    expect(_noLoopIndexes.length, greaterThanOrEqualTo(6),
        reason: 'должно быть не меньше шести бесцикловых уровней');
  });

  test('на обычных уровнях циклы тоже работают (лимиты и проходимость)', () {
    for (var i = 0; i < blockLevels.length; i++) {
      if (_noLoopIndexes.contains(i)) continue;
      final commands = mazeCommands(blockLevels[i]);
      expect(commands, isNotNull);
      final program = flatSolution(commands!);
      final sim = simulateBlocks(program, blockLevels[i]);
      expect(sim.crashed, isFalse, reason: 'уровень ${i + 1}');
      expect(sim.x == blockLevels[i].goalX && sim.y == blockLevels[i].goalY,
          isTrue, reason: 'уровень ${i + 1}');
    }
  });
}
