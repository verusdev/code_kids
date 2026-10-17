// Проверка уровней «Программируй блоками» и «Пиксель-арт» (1–45).
//
// Запуск:  dart run tool/blocks_pixel_ext_check.dart
//
// Утилита читает реальные данные уровней прямо из исходников игр
// (lib/games/blocks/blocks_game.dart и lib/games/pixel/pixel_game.dart),
// не импортируя Flutter, и проверяет:
//
//   * blocks 1–45 — цель достижима (BFS по «клетка + направление»), и для
//     каждого уровня симулируется программа-решение с соблюдением лимитов
//     редактора: глубина контейнеров ≤ 2, блоков ≤ 40, шагов ≤ 300,
//     «повторить» 2..6. Для уровней 36–41 (там, где циклы в игре отключены)
//     решение обязано использовать «мою функцию»: вызов разворачивается в
//     команды определения, вызовов ≤ 5, тело функции — только простые команды
//     (2..5 штук), вложенность функций запрещена.
//
//   * pixel 1–45 — цель непуста и в пределах поля; программа-решение
//     симулируется (кисточка стартует в (0,0)) и результат сравнивается с
//     целью. Для уровней 1–30 цвет не задан — считается «чёрный по умолчанию»
//     (сравниваются только клетки). Для уровней 31–45 выполняется цветная
//     сверка: цвет каждой закрашенной клетки обязан совпасть с целью.
import 'dart:collection';
import 'dart:io';

final _dirDx = [0, 1, 0, -1];
final _dirDy = [-1, 0, 1, 0];

int _dirIndex(String name) => switch (name) {
      'up' => 0,
      'right' => 1,
      'down' => 2,
      'left' => 3,
      _ => throw FormatException('Неизвестное направление: $name'),
    };

// ---------------------------------------------------------------------------
// Разбор исходников (те же приёмы, что в tool/level_check.dart).
// ---------------------------------------------------------------------------

List<String> extractCalls(String source, String prefix) {
  final result = <String>[];
  var i = 0;
  while (true) {
    final start = source.indexOf('$prefix(', i);
    if (start < 0) break;
    var depth = 0;
    var j = start + prefix.length;
    var inString = false;
    var closed = false;
    for (; j < source.length; j++) {
      final ch = source[j];
      if (inString) {
        if (ch == r'\') j++;
        if (ch == "'") inString = false;
        continue;
      }
      if (ch == "'") {
        inString = true;
      } else if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
        if (depth == 0) {
          result.add(source.substring(start, j + 1));
          i = j + 1;
          closed = true;
          break;
        }
      }
    }
    if (!closed) throw FormatException('Несбалансированные скобки в $prefix');
  }
  return result;
}

List<String> _realLevels(String source, String prefix) =>
    extractCalls(source, prefix).where((b) => !b.contains('required this.')).toList();

int _intField(String block, String name) {
  final m = RegExp('$name:\\s*(\\d+)').firstMatch(block);
  if (m == null) throw FormatException('Нет поля $name');
  return int.parse(m.group(1)!);
}

String? _enumField(String block, String name) =>
    RegExp('$name:\\s*\\w+\\.(\\w+)').firstMatch(block)?.group(1);

/// Содержимое фигурных скобок поля `name: {...}`, либо null.
String? _bracesField(String block, String name) {
  final key = block.indexOf('$name:');
  if (key < 0) return null;
  final open = block.indexOf('{', key);
  if (open < 0) return null;
  var depth = 0;
  for (var k = open; k < block.length; k++) {
    final ch = block[k];
    if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) return block.substring(open + 1, k);
    }
  }
  throw FormatException('Несбалансированные скобки у $name');
}

Set<int> _numbersIn(String content) => RegExp(r'-?\d+')
    .allMatches(content)
    .map((m) => int.parse(m.group(0)!))
    .toSet();

Set<int> _parseWalls(String block, int cols) {
  if (RegExp(r'walls:\s*\{\s*\}').hasMatch(block)) return {};
  final m = RegExp(r'walls:\s*_walls\((\d+),').firstMatch(block);
  if (m == null) throw FormatException('Не удалось разобрать walls');
  if (int.parse(m.group(1)!) != cols) {
    throw FormatException('walls использует другую ширину поля');
  }
  final bracket = block.indexOf('[', m.end);
  var depth = 0;
  var end = -1;
  for (var k = bracket; k < block.length; k++) {
    final ch = block[k];
    if (ch == '[') depth++;
    if (ch == ']') {
      depth--;
      if (depth == 0) {
        end = k;
        break;
      }
    }
  }
  final inner = block.substring(bracket + 1, end);
  return RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]')
      .allMatches(inner)
      .map((mm) => int.parse(mm.group(2)!) * cols + int.parse(mm.group(1)!))
      .toSet();
}

// ---------------------------------------------------------------------------
// Уровни блочной игры.
// ---------------------------------------------------------------------------

class MazeData {
  MazeData({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.startDir,
    required this.goalX,
    required this.goalY,
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final int startDir;
  final int goalX;
  final int goalY;
}

List<MazeData> parseBlockLevels(String path) {
  final source = File(path).readAsStringSync();
  return _realLevels(source, 'MazeLevel').map((block) {
    final cols = _intField(block, 'cols');
    final dir = _enumField(block, 'startDir');
    if (dir == null) throw FormatException('Нет startDir');
    return MazeData(
      cols: cols,
      rows: _intField(block, 'rows'),
      walls: _parseWalls(block, cols),
      startX: _intField(block, 'startX'),
      startY: _intField(block, 'startY'),
      startDir: _dirIndex(dir),
      goalX: _intField(block, 'goalX'),
      goalY: _intField(block, 'goalY'),
    );
  }).toList();
}

/// Индексы (0-based) уровней, где циклы отключены. Извлекаем из исходника,
/// чтобы не дублировать константу.
Set<int> parseNoLoopIndexes(String source) {
  final m = RegExp(r'_noLoopLevelIndexes\s*=\s*\{([^}]*)\}').firstMatch(source);
  if (m == null) return {};
  return _numbersIn(m.group(1)!);
}

bool _blocked(MazeData level, int x, int y) =>
    x < 0 || y < 0 || x >= level.cols || y >= level.rows ||
    level.walls.contains(y * level.cols + x);

/// Достижима ли цель; возвращает длину кратчайшего пути в «шагах».
int? mazeReachable(MazeData level) {
  final start = (level.startX, level.startY, level.startDir);
  final visited = <String>{'${start.$1},${start.$2},${start.$3}'};
  final queue = Queue<(int, int, int, int)>();
  queue.add((start.$1, start.$2, start.$3, 0));
  while (queue.isNotEmpty) {
    final (x, y, d, steps) = queue.removeFirst();
    if (x == level.goalX && y == level.goalY) return steps;
    for (final nd in [(d + 1) % 4, (d + 3) % 4]) {
      if (visited.add('$x,$y,$nd')) queue.add((x, y, nd, steps));
    }
    final nx = x + _dirDx[d];
    final ny = y + _dirDy[d];
    if (!_blocked(level, nx, ny) && visited.add('$nx,$ny,$d')) {
      queue.add((nx, ny, d, steps + 1));
    }
  }
  return null;
}

/// Кратчайшая последовательность команд ['F' | 'L' | 'R'] до цели.
List<String>? mazeCommands(MazeData level) {
  final startKey = '${level.startX},${level.startY},${level.startDir}';
  final prev = <String, String>{startKey: ''};
  final prevDir = <String, int>{};
  final queue = Queue<(int, int, int)>();
  queue.add((level.startX, level.startY, level.startDir));
  String? goalKey;
  while (queue.isNotEmpty) {
    final (x, y, d) = queue.removeFirst();
    final key = '$x,$y,$d';
    if (x == level.goalX && y == level.goalY) {
      goalKey = key;
      break;
    }
    for (final nd in [(d + 1) % 4, (d + 3) % 4]) {
      final nk = '$x,$y,$nd';
      if (!prev.containsKey(nk)) {
        prev[nk] = key;
        prevDir[nk] = d;
        queue.add((x, y, nd));
      }
    }
    final nx = x + _dirDx[d];
    final ny = y + _dirDy[d];
    final nk = '$nx,$ny,$d';
    if (!_blocked(level, nx, ny) && !prev.containsKey(nk)) {
      prev[nk] = key;
      prevDir[nk] = d;
      queue.add((nx, ny, d));
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
  var d = level.startDir;
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
      // Ребро-шаг: направление то же, позиция меняется.
      commands.add('F');
    }
    d = nd;
    px = nx;
    py = ny;
  }
  return commands;
}

// ---------------------------------------------------------------------------
// Программа блоков и её симуляция (с развёрткой «моей функции»).
// ---------------------------------------------------------------------------

sealed class BNode {}

class BCmd extends BNode {
  BCmd(this.id);
  final String id; // forward | left | right
}

class BRep extends BNode {
  BRep(this.times, this.body);
  final int times;
  final List<BNode> body;
}

class BIf extends BNode {
  BIf(this.body);
  final List<BNode> body;
}

class BCall extends BNode {
  BCall();
}

int _countB(List<BNode> nodes) {
  var total = 0;
  for (final n in nodes) {
    total++;
    if (n is BRep) total += _countB(n.body);
    if (n is BIf) total += _countB(n.body);
  }
  return total;
}

int _depthB(List<BNode> nodes, int depth) {
  var best = depth;
  for (final n in nodes) {
    if (n is BRep) {
      final d = _depthB(n.body, depth + 1);
      if (d > best) best = d;
    }
    if (n is BIf) {
      final d = _depthB(n.body, depth + 1);
      if (d > best) best = d;
    }
  }
  return best;
}

int _countCallsB(List<BNode> nodes) {
  var total = 0;
  for (final n in nodes) {
    if (n is BCall) total++;
    if (n is BRep) total += _countCallsB(n.body);
    if (n is BIf) total += _countCallsB(n.body);
  }
  return total;
}

/// Есть ли в программе контейнеры (цикл/условие) — на «бесцикловых» уровнях
/// их быть не должно.
bool _hasContainers(List<BNode> nodes) {
  for (final n in nodes) {
    if (n is BRep || n is BIf) return true;
  }
  return false;
}

class BSim {
  BSim({
    required this.x,
    required this.y,
    required this.crashed,
    required this.steps,
    required this.depth,
    required this.blocks,
    required this.calls,
  });

  final int x;
  final int y;
  final bool crashed;
  final int steps;
  final int depth;
  final int blocks;
  final int calls;
}

BSim simulateB(
  List<BNode> program,
  List<BNode>? function,
  MazeData level, {
  int maxSteps = 300,
}) {
  var x = level.startX;
  var y = level.startY;
  var d = level.startDir;
  var steps = 0;
  var crashed = false;

  void run(List<BNode> nodes) {
    for (final n in nodes) {
      if (crashed || steps >= maxSteps) return;
      switch (n) {
        case BCmd():
          steps++;
          switch (n.id) {
            case 'left':
              d = (d + 3) % 4;
            case 'right':
              d = (d + 1) % 4;
            case 'forward':
              final nx = x + _dirDx[d];
              final ny = y + _dirDy[d];
              if (_blocked(level, nx, ny)) {
                crashed = true;
              } else {
                x = nx;
                y = ny;
              }
          }
        case BRep():
          for (var i = 0; i < n.times && !crashed && steps < maxSteps; i++) {
            run(n.body);
          }
        case BIf():
          if (_blocked(level, x + _dirDx[d], y + _dirDy[d])) run(n.body);
        case BCall():
          if (function != null) run(function);
      }
    }
  }

  run(program);
  return BSim(
    x: x,
    y: y,
    crashed: crashed,
    steps: steps,
    depth: _depthB(program, 0),
    blocks: _countB(program),
    calls: _countCallsB(program),
  );
}

/// Программа из последовательности команд с циклом на длинных отрезках
/// «вперёд» (для уровней, где циклы доступны).
List<BNode> flatSolution(List<String> commands) {
  final nodes = <BNode>[];
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
          nodes.add(BCmd('forward'));
          left -= 1;
        } else {
          final take = left >= 6 ? 6 : left;
          nodes.add(BRep(take, [BCmd('forward')]));
          left -= take;
        }
      }
      i += run;
    } else {
      nodes.add(BCmd(commands[i] == 'R' ? 'right' : 'left'));
      i++;
    }
  }
  return nodes;
}

/// Программа «без циклов»: длинные отрезки «вперёд» проходятся вызовами
/// «моей функции» (тело — [funcLen] шагов вперёд), остаток — одиночными шагами.
/// Вызовов не больше [kMaxCalls].
({List<BNode> program, List<BNode> function}) callSolution(
  List<String> commands, {
  int maxCalls = 5,
}) {
  var totalForwards = commands.where((c) => c == 'F').length;
  final funcLen = totalForwards >= 5 ? 5 : (totalForwards >= 2 ? totalForwards : 2);
  final function = <BNode>[
    for (var i = 0; i < funcLen; i++) BCmd('forward'),
  ];
  final nodes = <BNode>[];
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
        nodes.add(BCall());
        left -= funcLen;
        budget--;
      }
      while (left > 0) {
        nodes.add(BCmd('forward'));
        left--;
      }
      i += run;
    } else {
      nodes.add(BCmd(commands[i] == 'R' ? 'right' : 'left'));
      i++;
    }
  }
  return (program: nodes, function: function);
}

// ---------------------------------------------------------------------------
// Уровни пиксель-арта.
// ---------------------------------------------------------------------------

class PixelData {
  PixelData({
    required this.cols,
    required this.rows,
    required this.target,
    required this.colorTarget,
  });

  final int cols;
  final int rows;
  final Set<int> target;

  /// Клетка → цвет (1..4); null — уровень без цветов.
  final Map<int, int>? colorTarget;
}

List<PixelData> parsePixelLevels(String path) {
  final source = File(path).readAsStringSync();
  return _realLevels(source, 'PixelLevel').map((block) {
    final cols = _intField(block, 'cols');
    final rows = _intField(block, 'rows');
    final targetRaw = _bracesField(block, 'target');
    if (targetRaw == null) throw FormatException('Нет поля target');
    final target = _numbersIn(targetRaw);
    final colorRaw = _bracesField(block, 'colorTarget');
    Map<int, int>? colorTarget;
    if (colorRaw != null) {
      colorTarget = {};
      for (final m in RegExp(r'(\d+)\s*:\s*(\d+)').allMatches(colorRaw)) {
        colorTarget[int.parse(m.group(1)!)] = int.parse(m.group(2)!);
      }
    }
    return PixelData(
      cols: cols,
      rows: rows,
      target: target,
      colorTarget: colorTarget,
    );
  }).toList();
}

/// Симуляция кисточки по списку идентификаторов команд.
/// Возвращает (цвета клеток, достигнут ли лимит шагов).
({Map<int, int> colors, bool hitLimit}) simulatePixelIds(
  List<String> commands,
  int cols,
  int rows, {
  int maxSteps = 300,
}) {
  const colorIds = ['color_red', 'color_blue', 'color_yellow', 'color_green'];
  final colors = <int, int>{};
  var x = 0;
  var y = 0;
  var brush = 0;
  var steps = 0;
  for (final id in commands) {
    if (steps >= maxSteps) return (colors: colors, hitLimit: true);
    steps++;
    final color = colorIds.indexOf(id);
    if (color >= 0) {
      brush = color + 1;
      continue;
    }
    switch (id) {
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
      default:
        throw FormatException('Неизвестная команда кисти: $id');
    }
  }
  return (colors: colors, hitLimit: false);
}

/// Строит программу-решение «змейкой»: клетки цели обходятся по строкам
/// (нечётные строки — справа налево), кисточка меняет цвет при необходимости
/// и красит только целевые клетки.
List<String> pixelSolution(PixelData level) {
  final cells = level.target.toList()
    ..sort((a, b) {
      final ay = a ~/ level.cols;
      final by = b ~/ level.cols;
      if (ay != by) return ay.compareTo(by);
      final ax = a % level.cols;
      final bx = b % level.cols;
      return ay.isEven ? ax.compareTo(bx) : bx.compareTo(ax);
    });

  const colorIds = ['color_red', 'color_blue', 'color_yellow', 'color_green'];
  final commands = <String>[];
  var x = 0;
  var y = 0;
  var brush = 0;
  for (final cell in cells) {
    final tx = cell % level.cols;
    final ty = cell ~/ level.cols;
    while (x < tx) {
      commands.add('right');
      x++;
    }
    while (x > tx) {
      commands.add('left');
      x--;
    }
    while (y < ty) {
      commands.add('down');
      y++;
    }
    while (y > ty) {
      commands.add('up');
      y--;
    }
    final want = level.colorTarget?[cell] ?? 0;
    if (want != brush) {
      if (want < 1 || want > 4) {
        throw FormatException('Неизвестный цвет $want в клетке $cell');
      }
      commands.add(colorIds[want - 1]);
      brush = want;
    }
    commands.add('paint');
  }
  return commands;
}

// ---------------------------------------------------------------------------
// Основная проверка.
// ---------------------------------------------------------------------------

void main() {
  final root = Directory.current.path;
  final sep = Platform.pathSeparator;
  final blocksFile = '$root${sep}lib${sep}games${sep}blocks${sep}blocks_game.dart';
  final pixelFile = '$root${sep}lib${sep}games${sep}pixel${sep}pixel_game.dart';

  final problems = <String>[];
  final blocksSource = File(blocksFile).readAsStringSync();
  final noLoop = parseNoLoopIndexes(blocksSource); // 0-based

  // ---- Блоки ----
  var funcLevels = 0;
  try {
    final levels = parseBlockLevels(blocksFile);
    for (var i = 0; i < levels.length; i++) {
      final n = i + 1;
      final level = levels[i];
      final levelProblems = <String>[];

      final reach = mazeReachable(level);
      if (reach == null) {
        levelProblems.add('цель недостижима геометрически');
      }
      if (level.walls.contains(level.startY * level.cols + level.startX)) {
        levelProblems.add('старт на стене');
      }
      if (level.walls.contains(level.goalY * level.cols + level.goalX)) {
        levelProblems.add('цель на стене');
      }

      final commands = mazeCommands(level);
      BSim? sim;
      if (commands == null) {
        levelProblems.add('нет пути до цели');
      } else {
        final isNoLoop = noLoop.contains(i);
        List<BNode> program;
        List<BNode>? function;
        if (isNoLoop) {
          final built = callSolution(commands);
          program = built.program;
          function = built.function;
          if (function.length < 2 || function.length > 5) {
            levelProblems.add('тело функции ${function.length} команд (нужно 2..5)');
          }
          if (function.any((f) => f is! BCmd)) {
            levelProblems.add('в теле функции есть не-команда');
          }
          if (_countCallsB(program) == 0) {
            levelProblems.add('нет вызова «моей функции»');
          }
          if (_countCallsB(program) > 5) {
            levelProblems.add('вызовов ${_countCallsB(program)} > 5');
          }
          if (_hasContainers(program)) {
            levelProblems.add('на бесцикловом уровне есть цикл/условие');
          }
          funcLevels++;
        } else {
          program = flatSolution(commands);
          function = null;
        }

        sim = simulateB(program, function, level);
        if (sim.crashed) levelProblems.add('решение врезается');
        if (!sim.crashed &&
            (sim.x != level.goalX || sim.y != level.goalY)) {
          levelProblems.add(
              'решение не доходит (${sim.x},${sim.y}) ≠ '
              '(${level.goalX},${level.goalY})');
        }
        if (sim.depth > 2) levelProblems.add('глубина ${sim.depth} > 2');
        if (sim.blocks > 40) levelProblems.add('блоков ${sim.blocks} > 40');
        if (sim.steps > 300) levelProblems.add('шагов ${sim.steps} > 300');
        if (_hasBadTimes(program)) levelProblems.add('«повторить» вне 2..6');
        if (_hasBadFunctionTimes(function)) {
          levelProblems.add('в функции «повторить» вне 2..6');
        }
      }

      if (levelProblems.isEmpty) {
        stdout.writeln('  ✓ блоки $n: решаемо, блоков ${sim!.blocks}, '
            'шагов ${sim.steps}');
      } else {
        stdout.writeln('  ✗ блоки $n: ${levelProblems.join('; ')}');
        problems.addAll(levelProblems.map((p) => 'блоки $n: $p'));
      }
    }
    stdout.writeln('  • уровень блоков с «моей функцией»: $funcLevels '
        '(ожидалось ≥ 6)');
  } catch (e) {
    problems.add('блоки: ошибка разбора/проверки: $e');
  }

  // ---- Пиксель ----
  var colorLevels = 0;
  try {
    final levels = parsePixelLevels(pixelFile);
    for (var i = 0; i < levels.length; i++) {
      final n = i + 1;
      final level = levels[i];
      final levelProblems = <String>[];
      final colorful = level.colorTarget != null;

      if (level.target.isEmpty) levelProblems.add('пустая цель');
      for (final c in level.target) {
        if (c < 0 || c >= level.cols * level.rows) {
          levelProblems.add('клетка $c вне поля');
        }
      }
      if (colorful) {
        colorLevels++;
        if (level.colorTarget!.keys.toSet().difference(level.target).isNotEmpty ||
            level.target.difference(level.colorTarget!.keys.toSet()).isNotEmpty) {
          levelProblems.add('colorTarget и target расходятся');
        }
        for (final v in level.colorTarget!.values) {
          if (v < 1 || v > 4) levelProblems.add('цвет $v вне 1..4');
        }
        final used = level.colorTarget!.values.toSet().length;
        if (used > 3) levelProblems.add('цветов $used > 3');
      } else if (i >= 30) {
        levelProblems.add('уровень 31+ без цветов');
      }

      final commands = pixelSolution(level);
      final sim = simulatePixelIds(commands, level.cols, level.rows);
      if (sim.hitLimit) {
        levelProblems.add('решение превышает лимит шагов');
      } else if (colorful) {
        if (sim.colors.length != level.colorTarget!.length) {
          levelProblems.add('клеток ${sim.colors.length}, '
              'в цели ${level.colorTarget!.length}');
        } else {
          for (final entry in level.colorTarget!.entries) {
            if (sim.colors[entry.key] != entry.value) {
              levelProblems.add('клетка ${entry.key}: цвет '
                  '${sim.colors[entry.key]} ≠ ${entry.value}');
              break;
            }
          }
        }
      } else {
        if (sim.colors.keys.toSet().length != level.target.length ||
            !sim.colors.keys.toSet().containsAll(level.target)) {
          levelProblems.add('клеток ${sim.colors.length}, '
              'в цели ${level.target.length}');
        }
        if (sim.colors.values.any((v) => v != 0)) {
          levelProblems.add('на бесцветном уровне кисть красит цветом');
        }
      }

      if (levelProblems.isEmpty) {
        stdout.writeln('  ✓ пиксель $n: цель ${level.target.length} клеток'
            '${colorful ? ', цветов ${level.colorTarget!.values.toSet().length}' : ''}, '
            'команд ${commands.length}');
      } else {
        stdout.writeln('  ✗ пиксель $n: ${levelProblems.join('; ')}');
        problems.addAll(levelProblems.map((p) => 'пиксель $n: $p'));
      }
    }
    stdout.writeln('  • цветных уровней: $colorLevels '
        '(ожидалось ≥ 15 в диапазоне 31–45)');
  } catch (e) {
    problems.add('пиксель: ошибка разбора/проверки: $e');
  }

  stdout.writeln('─' * 52);
  if (funcLevels < 6) {
    problems.add('уровней с «моей функцией» $funcLevels, ожидалось ≥ 6');
  }
  if (colorLevels < 15) {
    problems.add('цветных уровней $colorLevels, ожидалось ≥ 15');
  }

  if (problems.isEmpty) {
    stdout.writeln('  ✓ блоки и пиксель: все уровни проверены');
    stdout.writeln('ВСЁ ЗЕЛЁНОЕ ✅');
  } else {
    stdout.writeln('  ✗ проблем: ${problems.length}');
    for (final p in problems) {
      stdout.writeln('      $p');
    }
    exit(1);
  }
}

bool _hasBadTimes(List<BNode> nodes) {
  for (final n in nodes) {
    if (n is BRep) {
      if (n.times < 2 || n.times > 6) return true;
      if (_hasBadTimes(n.body)) return true;
    }
    if (n is BIf && _hasBadTimes(n.body)) return true;
  }
  return false;
}

bool _hasBadFunctionTimes(List<BNode>? function) {
  if (function == null) return false;
  return _hasBadTimes(function);
}
