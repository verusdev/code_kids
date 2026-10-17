// Проверка решаемости уровней «Код-Квеста».
//
// Запуск:  dart run tool/level_check.dart
//
// Утилита читает реальные данные уровней прямо из исходников игр
// (lib/games/**), не импортируя Flutter, и проверяет:
//   * maze   — достижимость цели (BFS по состояниям «клетка + направление»);
//   * stars  — сбор ВСЕХ звёзд (BFS по состояниям «клетка + маска звёзд»);
//   * blocks — достижимость цели (BFS) + для уровней 16–30 симуляция явной
//              программы-решения в пределах лимитов редактора;
//   * pixel  — корректность цели + для уровней 16–30 симуляция программы-
//              решения, совпадающей с целью точно;
//   * bug    — симуляция программы: с исправленной командой робот доходит
//              до цели, с оригинальной (с багом) — не доходит или врезается;
//   * code   — пересчёт двоичных чисел, шифра Цезаря и цифрового кода
//              чистыми функциями из code_logic.dart;
//   * quiz-игры (pattern, odd, steps, parts, causes, rules) — структурные
//              проверки: индексы ответов в пределах списков, шаги уникальны.
import 'dart:collection';
import 'dart:io';

import 'package:code_kids/games/secret_code/code_logic.dart';

// ---------------------------------------------------------------------------
// Мини-модели уровней (только для проверки).
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
  final Set<int> walls; // индекс = y * cols + x
  final int startX;
  final int startY;
  final int startDir; // 0 up, 1 right, 2 down, 3 left
  final int goalX;
  final int goalY;
}

class StarsData {
  StarsData({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.stars,
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final List<int> stars; // индексы клеток
}

// ---------------------------------------------------------------------------
// Чтение и парсинг исходников.
// ---------------------------------------------------------------------------

final _dirDx = [0, 1, 0, -1];
final _dirDy = [-1, 0, 1, 0];

int _dirFromName(String name) => switch (name) {
      'up' => 0,
      'right' => 1,
      'down' => 2,
      'left' => 3,
      _ => throw FormatException('Неизвестное направление: $name'),
    };

/// Возвращает текст всех блоков `<prefix>(...)` с балансом скобок,
/// с учётом одинарных строк Dart.
List<String> extractCalls(String source, String prefix) {
  final result = <String>[];
  var i = 0;
  while (true) {
    final start = source.indexOf('$prefix(', i);
    if (start < 0) break;
    var depth = 0;
    var j = start + prefix.length;
    var inString = false;
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
          break;
        }
      }
    }
    if (depth != 0) {
      throw FormatException('Несбалансированные скобки в блоке $prefix');
    }
  }
  return result;
}

/// Извлекает значение числового поля `name: 123`.
int intField(String block, String name) {
  final m = RegExp('$name:\\s*(\\d+)').firstMatch(block);
  if (m == null) throw FormatException('Нет поля $name в блоке');
  return int.parse(m.group(1)!);
}

/// Извлекает имя значения перечисления `name: Direction.up`.
String? enumField(String block, String name) {
  return RegExp('$name:\\s*\\w+\\.(\\w+)').firstMatch(block)?.group(1);
}

/// Отфильтровывает блоки, являющиеся определением конструктора класса
/// (содержат `required this.`), — это не данные уровней.
List<String> realLevels(String source, String prefix) =>
    extractCalls(source, prefix)
        .where((b) => !b.contains('required this.'))
        .toList();

/// Извлекает содержимое первого поля `name: [...]` (список верхнего уровня).
String listField(String block, String name) {
  final key = block.indexOf('$name:');
  if (key < 0) throw FormatException('Нет поля $name в блоке');
  var j = block.indexOf('[', key);
  if (j < 0) throw FormatException('Нет списка у поля $name');
  var depth = 0;
  var inString = false;
  for (var k = j; k < block.length; k++) {
    final ch = block[k];
    if (inString) {
      if (ch == r'\') k++;
      if (ch == "'") inString = false;
      continue;
    }
    if (ch == "'") {
      inString = true;
    } else if (ch == '[') {
      depth++;
    } else if (ch == ']') {
      depth--;
      if (depth == 0) return block.substring(j + 1, k);
    }
  }
  throw FormatException('Несбалансированный список у поля $name');
}

/// Извлекает содержимое поля `name: {...}` (множество верхнего уровня).
String setField(String block, String name) {
  final key = block.indexOf('$name:');
  if (key < 0) throw FormatException('Нет поля $name в блоке');
  final j = block.indexOf('{', key);
  if (j < 0) throw FormatException('Нет множества у поля $name');
  final k = block.indexOf('}', j);
  return block.substring(j + 1, k);
}

/// Количество элементов верхнего уровня внутри содержимого списка.
int countItems(String listContent) {
  if (listContent.trim().isEmpty) return 0;
  var count = 1;
  var depth = 0;
  var inString = false;
  for (var i = 0; i < listContent.length; i++) {
    final ch = listContent[i];
    if (inString) {
      if (ch == r'\') i++;
      if (ch == "'") inString = false;
      continue;
    }
    if (ch == "'") {
      inString = true;
    } else if (ch == '[' || ch == '{') {
      depth++;
    } else if (ch == ']' || ch == '}') {
      depth--;
    } else if (ch == ',' && depth == 0) {
      count++;
    }
  }
  // Последняя запятая не создаёт элемент.
  final trimmed = listContent.trimRight();
  return trimmed.endsWith(',') ? count - 1 : count;
}

/// Числа верхнего уровня внутри множества `{1, 2, 3}`.
List<int> numbersIn(String setContent) {
  return RegExp(r'-?\d+')
      .allMatches(setContent)
      .map((m) => int.parse(m.group(0)!))
      .toList();
}

Set<int> parseWalls(String block, int cols) {
  final empty = RegExp(r'walls:\s*\{\s*\}').firstMatch(block) != null;
  if (empty) return {};
  final m = RegExp(r'walls:\s*_walls\((\d+),\s*\[').firstMatch(block);
  if (m == null) throw FormatException('Не удалось разобрать walls');
  final wallsCols = int.parse(m.group(1)!);
  if (wallsCols != cols) {
    throw FormatException('walls использует $wallsCols колонок, cols = $cols');
  }
  final listStart = m.end - 1; // позиция '['
  var depth = 0;
  var end = -1;
  for (var k = listStart; k < block.length; k++) {
    if (block[k] == '[') depth++;
    if (block[k] == ']') {
      depth--;
      if (depth == 0) {
        end = k;
        break;
      }
    }
  }
  final inner = block.substring(listStart + 1, end);
  final cells = RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]')
      .allMatches(inner)
      .map((m) => (x: int.parse(m.group(1)!), y: int.parse(m.group(2)!)))
      .toList();
  return cells.map((c) => c.y * cols + c.x).toSet();
}

List<MazeData> parseMazeLevels(String file) {
  final source = File(file).readAsStringSync();
  return realLevels(source, 'MazeLevel').map((block) {
    final cols = intField(block, 'cols');
    final startX = intField(block, 'startX');
    final startY = intField(block, 'startY');
    final goalX = intField(block, 'goalX');
    final goalY = intField(block, 'goalY');
    final dirName = enumField(block, 'startDir');
    if (dirName == null) throw FormatException('Нет startDir в блоке');
    final level = MazeData(
      cols: cols,
      rows: intField(block, 'rows'),
      walls: parseWalls(block, cols),
      startX: startX,
      startY: startY,
      startDir: _dirFromName(dirName),
      goalX: goalX,
      goalY: goalY,
    );
    _checkBounds(level.cols, level.rows, [
      (startX, startY),
      (goalX, goalY),
    ]);
    for (final w in level.walls) {
      if (w < 0 || w >= level.cols * level.rows) {
        throw FormatException('Стена вне поля: $w');
      }
    }
    if (level.walls.contains(startY * cols + startX)) {
      throw FormatException('Старт на стене');
    }
    if (level.walls.contains(goalY * cols + goalX)) {
      throw FormatException('Цель на стене');
    }
    return level;
  }).toList();
}

List<StarsData> parseStarsLevels(String file) {
  final source = File(file).readAsStringSync();
  return realLevels(source, 'StarsLevel').map((block) {
    final cols = intField(block, 'cols');
    final startX = intField(block, 'startX');
    final startY = intField(block, 'startY');
    final starsList = listField(block, 'starCells');
    final stars = RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]')
        .allMatches(starsList)
        .map((m) => int.parse(m.group(2)!) * cols + int.parse(m.group(1)!))
        .toList();
    final level = StarsData(
      cols: cols,
      rows: intField(block, 'rows'),
      walls: parseWalls(block, cols),
      startX: startX,
      startY: startY,
      stars: stars,
    );
    _checkBounds(level.cols, level.rows, [(startX, startY)]);
    if (stars.isEmpty) throw FormatException('Уровень без звёзд');
    if (stars.toSet().length != stars.length) {
      throw FormatException('Две звезды в одной клетке');
    }
    for (final s in stars) {
      if (s < 0 || s >= cols * level.rows) throw FormatException('Звезда вне поля');
      if (level.walls.contains(s)) throw FormatException('Звезда на стене');
    }
    return level;
  }).toList();
}

void _checkBounds(int cols, int rows, List<(int, int)> cells) {
  for (final (x, y) in cells) {
    if (x < 0 || y < 0 || x >= cols || y >= rows) {
      throw FormatException('Клетка ($x, $y) вне поля $cols×$rows');
    }
  }
}

/// Извлекает значение числового поля `name: 123`, если оно есть.
int? tryIntField(String block, String name) {
  final m = RegExp('$name:\\s*(\\d+)').firstMatch(block);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Извлекает строковое поле `name: 'текст'`, если оно есть.
String? stringField(String block, String name) {
  return RegExp("$name:\\s*'([^']+)'").firstMatch(block)?.group(1);
}

// ---------------------------------------------------------------------------
// Уровни игры «Поймай багу» (мини-модель для проверки).
// ---------------------------------------------------------------------------

/// Уровень bug в коде проверки: программа — строки 'F' | 'L' | 'R'.
class BugData {
  BugData({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.startDir,
    required this.goalX,
    required this.goalY,
    required this.program,
    required this.bugIndex,
    required this.fixCount,
    required this.correctFix,
    required this.fixesText,
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final int startDir;
  final int goalX;
  final int goalY;
  final List<String> program;
  final int bugIndex;
  final int fixCount;
  final String correctFix; // F | L | R
  final String fixesText;
}

String _cmdChar(String name) => switch (name) {
      'forward' => 'F',
      'turnLeft' => 'L',
      'turnRight' => 'R',
      _ => throw FormatException('Неизвестная команда: $name'),
    };

/// Симуляция программы bug-уровня (семантика как в игре: вперёд в стену —
/// краш, дальше не выполняется).
({int x, int y, bool crashed}) simulateBug(
    BugData level, List<String> program) {
  var x = level.startX;
  var y = level.startY;
  var d = level.startDir;
  var crashed = false;
  for (final cmd in program) {
    if (cmd == 'F') {
      final nx = x + _dirDx[d];
      final ny = y + _dirDy[d];
      if (nx < 0 || ny < 0 || nx >= level.cols || ny >= level.rows ||
          level.walls.contains(ny * level.cols + nx)) {
        crashed = true;
        break;
      }
      x = nx;
      y = ny;
    } else if (cmd == 'L') {
      d = (d + 3) % 4;
    } else {
      d = (d + 1) % 4;
    }
  }
  return (x: x, y: y, crashed: crashed);
}

/// Список команд из блока вида `program: [BugCommand.forward, ...]`.
List<String> _commandsIn(String listContent) {
  return RegExp(r'BugCommand\.(\w+)')
      .allMatches(listContent)
      .map((m) => _cmdChar(m.group(1)!))
      .toList();
}

List<BugData> parseBugLevels(String file) {
  final source = File(file).readAsStringSync();
  return realLevels(source, 'BugLevel').map((block) {
    final cols = intField(block, 'cols');
    final dirName = enumField(block, 'startDir');
    if (dirName == null) throw FormatException('Нет startDir в блоке');
    final fixName = RegExp(r'correctFix:\s*BugCommand\.(\w+)')
        .firstMatch(block)
        ?.group(1);
    if (fixName == null) throw FormatException('Нет correctFix в блоке');
    final fixesText = listField(block, 'fixes');
    final level = BugData(
      cols: cols,
      rows: intField(block, 'rows'),
      walls: parseWalls(block, cols),
      startX: intField(block, 'startX'),
      startY: intField(block, 'startY'),
      startDir: _dirFromName(dirName),
      goalX: intField(block, 'goalX'),
      goalY: intField(block, 'goalY'),
      program: _commandsIn(listField(block, 'program')),
      bugIndex: intField(block, 'bugIndex'),
      fixCount: countItems(fixesText),
      correctFix: _cmdChar(fixName),
      fixesText: fixesText,
    );
    _checkBounds(level.cols, level.rows, [
      (level.startX, level.startY),
      (level.goalX, level.goalY),
    ]);
    if (level.walls.contains(level.startY * cols + level.startX)) {
      throw FormatException('Старт на стене');
    }
    if (level.walls.contains(level.goalY * cols + level.goalX)) {
      throw FormatException('Цель на стене');
    }
    return level;
  }).toList();
}

// ---------------------------------------------------------------------------
// Уровни игры «Секретный код» (мини-модель для проверки).
// ---------------------------------------------------------------------------

class CodeData {
  CodeData({
    required this.type,
    required this.bits,
    required this.number,
    required this.word,
    required this.shift,
    required this.options,
    required this.correctIndex,
  });

  final String type; // имя значения CodeType
  final List<int>? bits;
  final int? number;
  final String? word;
  final int? shift;
  final List<String> options;
  final int correctIndex;
}

/// Тексты вариантов ответа верхнего уровня в списке `options: ['а', 'б']`.
List<String> _stringItems(String listContent) {
  return RegExp(r"'([^']+)'")
      .allMatches(listContent)
      .map((m) => m.group(1)!)
      .toList();
}

List<CodeData> parseCodeLevels(String file) {
  final source = File(file).readAsStringSync();
  return realLevels(source, 'CodeLevel').map((block) {
    final typeName = enumField(block, 'type');
    if (typeName == null) throw FormatException('Нет type в блоке');
    final bitsMatch = RegExp(r'bits:\s*\[([^\]]*)\]').firstMatch(block);
    return CodeData(
      type: typeName,
      bits: bitsMatch == null
          ? null
          : RegExp(r'\d+')
              .allMatches(bitsMatch.group(1)!)
              .map((m) => int.parse(m.group(0)!))
              .toList(),
      number: tryIntField(block, 'number'),
      word: stringField(block, 'word'),
      shift: tryIntField(block, 'shift'),
      options: _stringItems(listField(block, 'options')),
      correctIndex: intField(block, 'correctIndex'),
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// BFS-проверки.
// ---------------------------------------------------------------------------

/// Достижима ли цель робота; возвращает длину кратчайшей программы
/// в «шагах вперёд» (повороты не считаются).
int? mazeGoalReachable(MazeData level) {
  final start = (x: level.startX, y: level.startY, d: level.startDir);
  final visited = <String>{'${start.x},${start.y},${start.d}'};
  final queue = Queue<(int, int, int, int)>();
  queue.add((start.x, start.y, start.d, 0));
  while (queue.isNotEmpty) {
    final (x, y, d, steps) = queue.removeFirst();
    if (x == level.goalX && y == level.goalY) return steps;
    // Повороты (без стоимости) — считаем только «вперёд».
    for (final nd in [(d + 1) % 4, (d + 3) % 4]) {
      final key = '$x,$y,$nd';
      if (visited.add(key)) queue.add((x, y, nd, steps));
    }
    final nx = x + _dirDx[d];
    final ny = y + _dirDy[d];
    if (nx >= 0 && ny >= 0 && nx < level.cols && ny < level.rows &&
        !level.walls.contains(ny * level.cols + nx)) {
      final key = '$nx,$ny,$d';
      if (visited.add(key)) queue.add((nx, ny, d, steps + 1));
    }
  }
  return null;
}

/// Список звёзд, недостижимых из старта (по отдельности).
List<String> starsUnreachable(StarsData level) {
  final seen = <int>{level.startY * level.cols + level.startX};
  final queue = Queue<(int, int)>();
  queue.add((level.startX, level.startY));
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    for (var d = 0; d < 4; d++) {
      final nx = x + _dirDx[d];
      final ny = y + _dirDy[d];
      if (nx < 0 || ny < 0 || nx >= level.cols || ny >= level.rows) continue;
      final cell = ny * level.cols + nx;
      if (level.walls.contains(cell) || !seen.add(cell)) continue;
      queue.add((nx, ny));
    }
  }
  return [
    for (var i = 0; i < level.stars.length; i++)
      if (!seen.contains(level.stars[i]))
        'звезда ${i + 1} (${level.stars[i] % level.cols},'
            '${level.stars[i] ~/ level.cols})',
  ];
}

/// Существует ли последовательность стрелок, собирающая все звёзды.
bool starsAllCollectible(StarsData level) {
  final total = 1 << level.stars.length;
  final starIndex = {for (var i = 0; i < level.stars.length; i++) level.stars[i]: i};
  final startKey = level.startY * level.cols + level.startX;
  var mask = 0;
  if (starIndex.containsKey(startKey)) mask = 1 << starIndex[startKey]!;
  final visited = <int>{(mask * level.cols * level.rows) + startKey};
  final queue = Queue<(int, int, int)>();
  queue.add((level.startX, level.startY, mask));
  while (queue.isNotEmpty) {
    final (x, y, cur) = queue.removeFirst();
    if (cur == total - 1) return true;
    for (var d = 0; d < 4; d++) {
      final nx = x + _dirDx[d];
      final ny = y + _dirDy[d];
      if (nx < 0 || ny < 0 || nx >= level.cols || ny >= level.rows) continue;
      final cell = ny * level.cols + nx;
      if (level.walls.contains(cell)) continue;
      final next = starIndex.containsKey(cell)
          ? cur | (1 << starIndex[cell]!)
          : cur;
      final key = next * level.cols * level.rows + cell;
      if (visited.add(key)) queue.add((nx, ny, next));
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Симулятор блоков (семантика игры: forward-в-стену = краш; «если впереди
// стена» выполняет тело, когда стена впереди).
// ---------------------------------------------------------------------------

sealed class Node {}
class Cmd extends Node {
  Cmd(this.id);
  final String id; // forward | left | right
}
class Rep extends Node {
  Rep(this.times, this.body);
  final int times;
  final List<Node> body;
}
class IfWall extends Node {
  IfWall(this.body);
  final List<Node> body;
}

class SimResult {
  SimResult({required this.x, required this.y, required this.crashed,
      required this.steps, required this.depth, required this.blocks});

  final int x;
  final int y;
  final bool crashed;
  final int steps;
  final int depth; // максимальная глубина вложенности контейнеров
  final int blocks; // всего блоков (как в countBlocks)
}

int countNodes(List<Node> nodes) {
  var total = 0;
  for (final node in nodes) {
    total++;
    if (node is Rep) total += countNodes(node.body);
    if (node is IfWall) total += countNodes(node.body);
  }
  return total;
}

int maxDepth(List<Node> nodes, int depth) {
  var best = depth;
  for (final node in nodes) {
    if (node is Rep) {
      final d = maxDepth(node.body, depth + 1);
      if (d > best) best = d;
    }
    if (node is IfWall) {
      final d = maxDepth(node.body, depth + 1);
      if (d > best) best = d;
    }
  }
  return best;
}

SimResult simulateBlocks(List<Node> program, MazeData level, {int maxSteps = 300}) {
  var x = level.startX;
  var y = level.startY;
  var d = level.startDir;
  var steps = 0;
  var crashed = false;

  bool blocked(int px, int py) =>
      px < 0 || py < 0 || px >= level.cols || py >= level.rows ||
      level.walls.contains(py * level.cols + px);

  void exec(List<Node> nodes) {
    for (final node in nodes) {
      if (crashed || steps >= maxSteps) return;
      switch (node) {
        case Cmd():
          steps++;
          switch (node.id) {
            case 'left':
              d = (d + 3) % 4;
            case 'right':
              d = (d + 1) % 4;
            case 'forward':
              final nx = x + _dirDx[d];
              final ny = y + _dirDy[d];
              if (blocked(nx, ny)) {
                crashed = true;
              } else {
                x = nx;
                y = ny;
              }
          }
        case Rep():
          for (var i = 0; i < node.times && !crashed && steps < maxSteps; i++) {
            exec(node.body);
          }
        case IfWall():
          if (blocked(x + _dirDx[d], y + _dirDy[d])) exec(node.body);
      }
    }
  }

  exec(program);
  return SimResult(
    x: x,
    y: y,
    crashed: crashed,
    steps: steps,
    depth: maxDepth(program, 0),
    blocks: countNodes(program),
  );
}

// ---------------------------------------------------------------------------
// Программы-решения для новых уровней blocks (16–30) и pixel (16–30).
//
// Ключ — номер уровня (1-based). Решения обязаны соблюдать лимиты редактора:
// глубина вложенности ≤ 2 контейнера, «повторить» 2..6, ≤ 40 блоков,
// ≤ 300 шагов.
// ---------------------------------------------------------------------------

/// Пути «вперёд» с редиректорами (семантика: повороты + шаги).
Node fwd(int n) => Rep(n, [Cmd('forward')]);
Node left() => Cmd('left');
Node right() => Cmd('right');

/// Программы-решения для уровней blocks 16–30.
final Map<int, List<Node>> blockSolutions = {
  // 16: змейка 8×8, три горизонтальные перегородки.
  16: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('forward'),
  ],
  // 17: вертикальная змейка 9×9, четыре перегородки.
  17: [
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'),
  ],
  // 18: лесенка вверх-вправо: узор «два вперёд — поворот» ×3.
  18: [
    Rep(3, [
      Rep(2, [Cmd('forward')]), Cmd('right'),
      Rep(2, [Cmd('forward')]), Cmd('left'),
    ]),
    Cmd('right'), Cmd('forward'),
  ],
  // 19: замок 8×8 с дверью справа, цель внутри.
  19: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(4, [Cmd('forward')]), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('forward'),
  ],
  // 20: пружина вниз-вправо через три вертикальные перегородки.
  20: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('forward'),
  ],
  // 21: вертикальная змейка 9×9 через три перегородки.
  21: [
    Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('forward'),
  ],
  // 22: обход креста по внешнему краю, вход в центр сверху.
  22: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(4, [Cmd('forward')]), Cmd('right'),
    Rep(4, [Cmd('forward')]), Cmd('right'),
    Cmd('forward'),
  ],
  // 23: двойная лесенка вверх-вправо: узор ×3 и вход в верхний угол.
  23: [
    Rep(3, [
      Rep(2, [Cmd('forward')]), Cmd('left'),
      Rep(2, [Cmd('forward')]), Cmd('right'),
    ]),
    Cmd('left'), Cmd('forward'), Cmd('right'), Cmd('forward'),
  ],
  // 24: пружина вниз-вправо: узор «два вперёд — поворот» ×3 и спуск в угол.
  24: [
    Rep(3, [
      Rep(2, [Cmd('forward')]), Cmd('left'),
      Rep(2, [Cmd('forward')]), Cmd('right'),
    ]),
    Cmd('forward'), Cmd('left'), Cmd('forward'),
  ],
  // 25: S-труба: шесть вперёд, два вниз, шесть назад.
  25: [
    Rep(6, [Cmd('forward')]), Cmd('right'), Rep(2, [Cmd('forward')]),
    Cmd('right'), Rep(6, [Cmd('forward')]), Cmd('left'),
    Rep(2, [Cmd('forward')]), Cmd('left'), Rep(6, [Cmd('forward')]),
    Cmd('forward'), Cmd('forward'),
  ],
  // 26: замок с дверью слева, цель внутри.
  26: [
    Rep(3, [Cmd('forward')]), Cmd('left'),
    Rep(2, [Cmd('forward')]),
    Cmd('forward'), Cmd('forward'), Cmd('right'), Cmd('forward'),
  ],
  // 27: большая змейка 9×9, четыре перегородки с проёмами на разных краях.
  27: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('right'),
    Cmd('forward'), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('left'),
    Cmd('forward'), Cmd('forward'), Cmd('left'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'),
  ],
  // 28: спираль: внешний круг + вход в замок сверху.
  28: [
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('right'),
    Rep(4, [Cmd('forward')]), Cmd('right'),
    Cmd('forward'), Cmd('forward'),
  ],
  // 29: пружина вверх-вправо: узор ×3 и финиш в верхнем углу.
  29: [
    Rep(3, [
      Rep(2, [Cmd('forward')]), Cmd('right'),
      Rep(2, [Cmd('forward')]), Cmd('left'),
    ]),
    Cmd('forward'), Cmd('right'), Cmd('forward'),
  ],
  // 30: финал 10×10: длинная змейка по краям + проход к замку через дверку слева.
  30: [
    // 9 вправо → (9,0); 9 вниз по правому краю → (9,9);
    // 7 влево → (2,9); 2 вверх → (2,7); 3 вправо через дверку → (5,7).
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('forward'),
    Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'), Cmd('forward'), Cmd('forward'),
    Cmd('right'),
    Rep(6, [Cmd('forward')]), Cmd('forward'),
    Cmd('right'),
    Rep(2, [Cmd('forward')]),
    Cmd('right'),
    Rep(2, [Cmd('forward')]), Cmd('forward'),
  ],
};

/// Программы-решения для уровней pixel 16–30 (команды paint/right/down/left/up).
sealed class Paint {}
class PCmd extends Paint {
  PCmd(this.id);
  final String id;
}
class PRep extends Paint {
  PRep(this.times, this.body);
  final int times;
  final List<Paint> body;
}

Paint p(String id) => PCmd(id);
Paint rep(int times, List<Paint> body) => PRep(times, body);

Set<int> simulatePaint(List<Paint> program, int cols, int rows) {
  final painted = <int>{};
  var x = 0;
  var y = 0;
  void exec(List<Paint> nodes) {
    for (final node in nodes) {
      switch (node) {
        case PCmd():
          switch (node.id) {
            case 'paint':
              painted.add(y * cols + x);
            case 'right':
              if (x < cols - 1) x++;
            case 'down':
              if (y < rows - 1) y++;
            case 'left':
              if (x > 0) x--;
            case 'up':
              if (y > 0) y--;
          }
        case PRep():
          for (var i = 0; i < node.times; i++) {
            exec(node.body);
          }
      }
    }
  }

  exec(program);
  return painted;
}

final Map<int, List<Paint>> pixelSolutions = {
  16: [
    p('down'), p('down'),
    rep(4, [p('paint'), p('right'), p('paint'), p('right')]),
    p('down'), p('down'), p('down'),
    rep(4, [p('paint'), p('left'), p('paint'), p('left')]),
  ],
  17: [
    rep(4, [p('paint'), p('right'), p('paint'), p('right')]),
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'), p('down'),
    rep(4, [p('paint'), p('left'), p('paint'), p('left')]),
    rep(3, [p('paint'), p('up'), p('paint'), p('up')]),
    p('paint'),
  ],
  18: [
    rep(3, [p('paint'), p('right'), p('paint'), p('right')]),
    p('paint'),
    p('left'), p('left'), p('left'),
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
  ],
  19: [
    rep(3, [p('paint'), p('right'), p('paint'), p('right')]),
    p('paint'),
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
  ],
  20: [
    p('paint'), p('right'),
    rep(3, [p('paint'), p('down'), p('paint'), p('right')]),
    p('down'), p('paint'),
  ],
  21: [
    p('right'), p('right'), p('right'), p('right'),
    rep(4, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
    p('up'), p('up'), p('up'), p('up'),
    p('left'), p('left'), p('left'), p('left'),
    rep(4, [p('paint'), p('right'), p('paint'), p('right')]),
    p('paint'),
  ],
  22: [
    rep(4, [p('paint'), p('down'), p('paint'), p('down')]),
    p('right'), p('right'),
    rep(4, [p('paint'), p('up'), p('paint'), p('up')]),
    p('right'), p('right'),
    rep(4, [p('paint'), p('down'), p('paint'), p('down')]),
    p('right'), p('right'),
    rep(4, [p('paint'), p('up'), p('paint'), p('up')]),
  ],
  23: [
    p('down'), p('down'), p('down'), p('down'),
    rep(3, [p('paint'), p('right'), p('paint'), p('right')]),
    p('paint'),
    p('up'), p('paint'),
    p('down'), p('down'), p('paint'),
  ],
  24: [
    p('right'),
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
    p('right'), p('right'), p('right'), p('right'),
    rep(3, [p('paint'), p('up'), p('paint'), p('up')]),
    p('paint'),
    p('down'), p('down'), p('down'), p('down'), p('down'), p('down'),
    p('left'), p('left'), p('left'),
    p('paint'), p('right'), p('paint'), p('right'), p('paint'),
  ],
  25: [
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
    p('up'), p('up'), p('up'), p('up'), p('up'),
    p('right'), p('paint'),
    p('right'), p('down'), p('paint'),
    p('right'), p('down'), p('paint'),
    p('up'), p('right'), p('paint'),
    p('up'), p('right'), p('paint'),
    p('up'), p('right'),
    rep(3, [p('paint'), p('down'), p('paint'), p('down')]),
    p('paint'),
  ],
  26: [
    p('right'), p('right'), p('right'), p('right'), p('right'), p('right'),
    rep(6, [p('paint'), p('left'), p('down')]),
    p('paint'),
    p('right'), p('right'), p('right'), p('right'), p('right'), p('right'),
    rep(3, [p('paint'), p('up'), p('paint'), p('up')]),
  ],
  27: [
    p('right'), p('right'), p('right'), p('right'),
    p('paint'),
    p('down'), p('left'),
    p('paint'), p('right'), p('paint'), p('right'), p('paint'),
    p('down'),
    p('left'), p('left'), p('left'),
    rep(2, [p('paint'), p('right'), p('paint'), p('right')]),
    p('paint'),
    p('down'),
    rep(3, [p('paint'), p('left'), p('paint'), p('left')]),
    p('right'), p('right'), p('right'), p('right'),
    p('down'),
    p('paint'), p('down'), p('paint'), p('down'),
  ],
  28: [
    rep(4, [p('paint'), p('right'), p('down')]),
    rep(4, [p('paint'), p('right'), p('down')]),
    p('paint'),
    p('up'), p('up'), p('up'), p('up'), p('up'), p('up'), p('up'),
    p('up'),
    rep(4, [p('paint'), p('left'), p('down')]),
    rep(2, [p('paint'), p('left'), p('down')]),
    rep(2, [p('paint'), p('left'), p('down')]),
    p('paint'),
  ],
  29: [
    rep(4, [
      rep(3, [p('paint'), p('right'), p('right'), p('paint')]),
      p('right'), p('down'),
      rep(3, [p('paint'), p('left'), p('left'), p('paint')]),
      p('left'), p('down'),
    ]),
  ],
  30: [
    rep(2, [
      rep(5, [p('paint'), p('right'), p('paint'), p('right')]),
      p('down'), p('down'),
      rep(5, [p('paint'), p('left'), p('paint'), p('left')]),
      p('down'), p('down'),
    ]),
    rep(5, [p('paint'), p('right'), p('paint'), p('right')]),
  ],
};

// ---------------------------------------------------------------------------
// Основная проверка.
// ---------------------------------------------------------------------------

void main() {
  final root = Directory.current.path;
  final lib = '$root${Platform.pathSeparator}lib${Platform.pathSeparator}games';

  final errors = <String>[];
  void report(String game, int total, List<String> problems) {
    if (problems.isEmpty) {
      stdout.writeln('  ✓ $game: $total уровней — все решаемы');
    } else {
      stdout.writeln('  ✗ $game: ${problems.length} проблем(ы)');
      for (final p in problems) {
        stdout.writeln('      $p');
      }
      errors.addAll(problems.map((p) => '$game: $p'));
    }
  }

  stdout.writeln('Проверка уровней «Код-Квест»');
  stdout.writeln('─' * 52);

  // 1. Робот-Лабиринт.
  try {
    final levels = parseMazeLevels('$lib${Platform.pathSeparator}robot_maze'
        '${Platform.pathSeparator}robot_maze_game.dart');
    final problems = <String>[];
    for (var i = 0; i < levels.length; i++) {
      final steps = mazeGoalReachable(levels[i]);
      if (steps == null) {
        problems.add('уровень ${i + 1}: цель недостижима');
      } else if (levels[i].cols <= 3 && levels[i].walls.isEmpty) {
        // тривиальный уровень — ок
      }
    }
    if (levels.length != 45) problems.add('всего ${levels.length}, ожидалось 45');
    report('maze', levels.length, problems);
  } catch (e) {
    report('maze', 0, ['ошибка парсинга: $e']);
  }

  // 2. Собери звёзды.
  try {
    final levels = parseStarsLevels(
        '$lib${Platform.pathSeparator}collect_stars${Platform.pathSeparator}collect_stars_game.dart');
    final problems = <String>[];
    for (var i = 0; i < levels.length; i++) {
      if (!starsAllCollectible(levels[i])) {
        problems.add('уровень ${i + 1}: не все звёзды собираемы '
            '(${starsUnreachable(levels[i]).join('; ')})');
      }
    }
    if (levels.length != 30) problems.add('всего ${levels.length}, ожидалось 30');
    report('stars', levels.length, problems);
  } catch (e) {
    report('stars', 0, ['ошибка парсинга: $e']);
  }

  // 3. Программируй блоками.
  try {
    final levels = parseMazeLevels(
        '$lib${Platform.pathSeparator}blocks${Platform.pathSeparator}blocks_game.dart');
    final problems = <String>[];
    for (var i = 0; i < levels.length; i++) {
      if (mazeGoalReachable(levels[i]) == null) {
        problems.add('уровень ${i + 1}: цель недостижима геометрически');
      }
    }
    // Явные решения для новых уровней 16–30.
    blockSolutions.forEach((number, program) {
      if (number - 1 >= levels.length) {
        problems.add('уровень $number: решения нет в списке уровней');
        return;
      }
      final level = levels[number - 1];
      final sim = simulateBlocks(program, level);
      final limitProblems = <String>[
        if (sim.crashed) 'врезался',
        if (sim.x != level.goalX || sim.y != level.goalY)
          'не дошёл (${sim.x},${sim.y}) ≠ (${level.goalX},${level.goalY})',
        if (sim.depth > 2) 'глубина ${sim.depth} > 2 (лимит редактора)',
        if (sim.blocks > 40) 'блоков ${sim.blocks} > 40',
        if (sim.steps > 300) 'шагов ${sim.steps} > 300',
      ];
      if (program.any((n) => n is Rep && (n.times < 2 || n.times > 6))) {
        limitProblems.add('повтор вне 2..6');
      }
      if (limitProblems.isNotEmpty) {
        problems.add('уровень $number: решение: ${limitProblems.join(', ')}');
      }
    });
    if (levels.length != 45) problems.add('всего ${levels.length}, ожидалось 45');
    report('blocks', levels.length, problems);
  } catch (e) {
    report('blocks', 0, ['ошибка парсинга: $e']);
  }

  // 4. Пиксель-арт.
  try {
    final source = File('$lib${Platform.pathSeparator}pixel'
            '${Platform.pathSeparator}pixel_game.dart')
        .readAsStringSync();
    final blocks = realLevels(source, 'PixelLevel');
    final problems = <String>[];
    for (var i = 0; i < blocks.length; i++) {
      final cols = intField(blocks[i], 'cols');
      final rows = intField(blocks[i], 'rows');
      final target = numbersIn(setField(blocks[i], 'target'));
      if (target.isEmpty) {
        problems.add('уровень ${i + 1}: пустая цель');
        continue;
      }
      if (target.any((c) => c < 0 || c >= cols * rows)) {
        problems.add('уровень ${i + 1}: клетка цели вне поля $cols×$rows');
      }
      if (target.toSet().length != target.length) {
        problems.add('уровень ${i + 1}: повтор клеток в цели');
      }
    }
    // Явные решения для новых уровней 16–30.
    pixelSolutions.forEach((number, program) {
      if (number - 1 >= blocks.length) return;
      final cols = intField(blocks[number - 1], 'cols');
      final rows = intField(blocks[number - 1], 'rows');
      final target = numbersIn(setField(blocks[number - 1], 'target')).toSet();
      final painted = simulatePaint(program, cols, rows);
      if (painted.length != target.length || !painted.containsAll(target)) {
        problems.add('уровень $number: решение даёт ${painted.length} клеток, '
            'цель ${target.length}; '
            'не хватает ${target.difference(painted).length}, '
            'лишних ${painted.difference(target).length}');
      }
    });
    if (blocks.length != 45) {
      problems.add('всего ${blocks.length}, ожидалось 45');
    }
    report('pixel', blocks.length, problems);
  } catch (e) {
    report('pixel', 0, ['ошибка парсинга: $e']);
  }

  // 5. Поймай багу: симуляция оригинальной и исправленной программ.
  try {
    final levels = parseBugLevels(
        '$lib${Platform.pathSeparator}bug${Platform.pathSeparator}bug_game.dart');
    final problems = <String>[];
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final n = i + 1;
      if (level.program.isEmpty) {
        problems.add('уровень $n: пустая программа');
        continue;
      }
      if (level.bugIndex < 0 || level.bugIndex >= level.program.length) {
        problems.add('уровень $n: bugIndex ${level.bugIndex} вне программы '
            'из ${level.program.length} команд');
        continue;
      }
      // Исправленная программа обязана доводить робота до цели.
      final fixed = List.of(level.program)
        ..[level.bugIndex] = level.correctFix;
      final run = simulateBug(level, fixed);
      if (run.crashed) {
        problems.add('уровень $n: исправленная программа врезается');
      } else if (run.x != level.goalX || run.y != level.goalY) {
        problems.add('уровень $n: исправленная программа не доходит '
            '(${run.x},${run.y}) ≠ (${level.goalX},${level.goalY})');
      }
      // Оригинал с багом обязан мешать: не добраться или врезаться.
      final buggy = simulateBug(level, level.program);
      final endsAtGoal = !buggy.crashed &&
          buggy.x == level.goalX && buggy.y == level.goalY;
      if (endsAtGoal) {
        problems.add('уровень $n: программа с багом всё равно доходит '
            'до цели — баг не мешает');
      }
      // Баг действительно отличается от правильной команды.
      if (level.program[level.bugIndex] == level.correctFix) {
        problems.add('уровень $n: правильная команда стоит и в баге');
      }
      // Варианты замены: 3–4 и среди них правильный.
      if (level.fixCount < 3 || level.fixCount > 4) {
        problems.add('уровень $n: вариантов замены ${level.fixCount}, '
            'ожидалось 3–4');
      }
      final fixName = switch (level.correctFix) {
        'F' => 'BugCommand.forward',
        'L' => 'BugCommand.turnLeft',
        _ => 'BugCommand.turnRight',
      };
      if (!level.fixesText.contains(fixName)) {
        problems.add('уровень $n: правильной команды нет среди вариантов '
            'замены');
      }
    }
    if (levels.length != 15) {
      problems.add('всего ${levels.length}, ожидалось 15');
    }
    report('bug', levels.length, problems);
  } catch (e) {
    report('bug', 0, ['ошибка парсинга: $e']);
  }

  // 6. Секретный код: пересчёт арифметики и шифров.
  try {
    final levels = parseCodeLevels(
        '$lib${Platform.pathSeparator}secret_code${Platform.pathSeparator}secret_code_game.dart');
    final problems = <String>[];
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final n = i + 1;
      if (level.correctIndex < 0 ||
          level.correctIndex >= level.options.length) {
        problems.add('уровень $n: correctIndex ${level.correctIndex} '
            'вне ${level.options.length} вариантов');
        continue;
      }
      if (level.options.length < 3 || level.options.length > 4) {
        problems.add('уровень $n: вариантов ${level.options.length}, '
            'ожидалось 3–4');
      }
      if (level.options.toSet().length != level.options.length) {
        problems.add('уровень $n: повторяющиеся варианты');
      }
      final correct = level.options[level.correctIndex];
      switch (level.type) {
        case 'binaryToNumber':
          final bits = level.bits;
          if (bits == null || bits.isEmpty) {
            problems.add('уровень $n: нет bits');
            break;
          }
          if (bits.any((b) => b != 0 && b != 1)) {
            problems.add('уровень $n: bits содержит не 0/1');
            break;
          }
          final value = binDecode(bits.join());
          if (correct != '$value') {
            problems.add('уровень $n: bits [${bits.join()}] = $value, '
                'а верный ответ «$correct»');
          }
        case 'numberToBinary':
          final number = level.number;
          if (number == null) {
            problems.add('уровень $n: нет number');
            break;
          }
          final code = binEncode(number);
          if (correct != code) {
            problems.add('уровень $n: $number в двоичном — $code, '
                'а верный ответ «$correct»');
          }
        case 'caesarDecode':
        case 'caesarEncode':
          final word = level.word;
          final shift = level.shift;
          if (word == null || shift == null) {
            problems.add('уровень $n: нет word/shift');
            break;
          }
          if (word.split('').any((ch) => !kRuAlphabet.contains(ch))) {
            problems.add('уровень $n: буква вне русского алфавита');
            break;
          }
          final expected = level.type == 'caesarDecode'
              ? word
              : caesarEncode(word, shift);
          if (correct != expected) {
            problems.add('уровень $n: шифр «$word» со сдвигом $shift — '
                '«$expected», а верный ответ «$correct»');
          }
          // Обратная операция обязана возвращать исходное слово.
          final shown = caesarEncode(word, shift);
          if (caesarDecode(shown, shift) != word) {
            problems.add('уровень $n: шифр Цезаря не обратим');
          }
        case 'digitDecode':
        case 'digitEncode':
          final word = level.word;
          if (word == null) {
            problems.add('уровень $n: нет word');
            break;
          }
          if (word.split('').any((ch) => !kRuAlphabet.contains(ch))) {
            problems.add('уровень $n: буква вне русского алфавита');
            break;
          }
          final expected = level.type == 'digitDecode'
              ? word
              : digitEncode(word);
          if (correct != expected) {
            problems.add('уровень $n: цифровой код «${digitEncode(word)}», '
                'а верный ответ «$correct»');
          }
          if (digitDecode(digitEncode(word)) != word) {
            problems.add('уровень $n: цифровой код не обратим');
          }
        default:
          problems.add('уровень $n: неизвестный тип ${level.type}');
      }
    }
    if (levels.length != 15) {
      problems.add('всего ${levels.length}, ожидалось 15');
    }
    report('code', levels.length, problems);
  } catch (e) {
    report('code', 0, ['ошибка парсинга: $e']);
  }

  // 7. Quiz-игры: структурные проверки индексов.
  void checkQuiz(String name, String file, String prefix, String optionsKey,
      {String? extraListKey,
      String? correctKey = 'correctIndex',
      int optionsMin = 3,
      int extraMin = 4}) {
    try {
      final source = File(file).readAsStringSync();
      final blocks = realLevels(source, prefix);
      final problems = <String>[];
      for (var i = 0; i < blocks.length; i++) {
        final optionsCount = countItems(listField(blocks[i], optionsKey));
        if (correctKey != null) {
          final correct = intField(blocks[i], correctKey);
          if (correct < 0 || correct >= optionsCount) {
            problems.add('уровень ${i + 1}: $correctKey $correct вне '
                '$optionsCount вариантов');
          }
        }
        if (optionsCount < optionsMin) {
          problems.add('уровень ${i + 1}: всего $optionsCount вариантов');
        }
        if (extraListKey != null) {
          final extraCount = countItems(listField(blocks[i], extraListKey));
          if (extraCount < extraMin) {
            problems.add('уровень ${i + 1}: $extraListKey — $extraCount, '
                'нужно ≥ $extraMin');
          }
        }
      }
      if (blocks.length != 30) {
        problems.add('всего ${blocks.length}, ожидалось 30');
      }
      report(name, blocks.length, problems);
    } catch (e) {
      report(name, 0, ['ошибка парсинга: $e']);
    }
  }

  final sep = Platform.pathSeparator;
  checkQuiz('pattern', '$lib$sep${'pattern'}$sep${'pattern_game.dart'}',
      'PatternLevel', 'options', extraListKey: 'sequence', extraMin: 3);
  checkQuiz('odd', '$lib$sep${'odd_one_out'}$sep${'odd_one_out_game.dart'}',
      'OddLevel', 'items', correctKey: 'oddIndex');
  checkQuiz('steps', '$lib$sep${'steps_order'}$sep${'steps_order_game.dart'}',
      'StepsLevel', 'steps', correctKey: null, optionsMin: 4);
  checkQuiz('parts', '$lib$sep${'parts'}$sep${'parts_game.dart'}',
      'PartsLevel', 'options', extraListKey: 'parts');
  checkQuiz('causes', '$lib$sep${'causes'}$sep${'causes_game.dart'}',
      'CauseLevel', 'options');
  checkQuiz('rules', '$lib$sep${'rules'}$sep${'rules_game.dart'}',
      'RulesLevel', 'options');

  stdout.writeln('─' * 52);
  if (errors.isEmpty) {
    stdout.writeln('Все проверки пройдены ✓');
  } else {
    stdout.writeln('Найдено проблем: ${errors.length}');
    exitCode = 1;
  }
}
