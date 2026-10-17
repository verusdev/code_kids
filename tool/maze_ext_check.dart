// Проверка решаемости уровней «Робот-Лабиринт», включая новые элементы
// (ключи, двери, телепорты) на уровнях 31–45.
//
// Запуск:  dart run tool/maze_ext_check.dart
//
// Утилита читает реальные данные уровней прямо из исходника
// lib/games/robot_maze/robot_maze_game.dart (без импорта Flutter) и для всех
// 45 уровней проверяет достижимость цели обходом в ширину (BFS) по
// расширенному состоянию «клетка + набор собранных ключей»:
//
//   * стена — пройти нельзя;
//   * дверь — пройти можно только с ключом того же цвета (учитывается порядок
//     сбора ключей: ключ, лежащий за дверью, эту же дверь не откроет);
//   * ключ — подбирается при наступлении на клетку и остаётся навсегда;
//   * телепорт — переносит робота на парную клетку и «гасится» до следующего
//     командного шага, поэтому перенос не зацикливается.
//
// Повороты в игре бесплатны и не ограничены, поэтому направление робота не
// входит в состояние: в каждой клетке можно считать доступными все 4 хода.
//
// Уровни 1–30 новых элементов не содержат — для них проверка сводится к
// обычной достижимости цели.
import 'dart:collection';
import 'dart:io';

// Направления движения: индекс → смещение (как Direction в игре).
final _dirDx = [0, 1, 0, -1];
final _dirDy = [-1, 0, 1, 0];

int _dirFromName(String name) => switch (name) {
      'up' => 0,
      'right' => 1,
      'down' => 2,
      'left' => 3,
      _ => throw FormatException('Неизвестное направление: $name'),
    };

/// Цвета ключей и дверей (совпадает с MazeColor в игре).
const _colorNames = ['red', 'blue', 'yellow'];

int _colorIndex(String name) {
  final i = _colorNames.indexOf(name);
  if (i < 0) throw FormatException('Неизвестный цвет: $name');
  return i;
}

// ---------------------------------------------------------------------------
// Мини-модель уровня (только для проверки).
// ---------------------------------------------------------------------------

class ExtMazeLevel {
  ExtMazeLevel({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.startDir,
    required this.goalX,
    required this.goalY,
    required this.keys,
    required this.doors,
    required this.teleports,
  });

  final int cols;
  final int rows;
  final Set<int> walls; // индекс = y * cols + x
  final int startX;
  final int startY;
  final int startDir; // не используется в BFS, но полезен для сообщений
  final int goalX;
  final int goalY;

  /// Индекс клетки → цвет ключа.
  final Map<int, int> keys;

  /// Индекс клетки → цвет двери.
  final Map<int, int> doors;

  /// Индекс клетки-вихря → индекс парной клетки.
  final Map<int, int> teleports;

  int get startCell => startY * cols + startX;
  int get goalCell => goalY * cols + goalX;

  /// Есть ли на уровне новые элементы.
  bool get hasExtras =>
      keys.isNotEmpty || doors.isNotEmpty || teleports.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Разбор исходника уровней.
// ---------------------------------------------------------------------------

/// Возвращает текст всех блоков `<prefix>(...)` с балансом скобок,
/// учитывая одинарные строки Dart (как в tool/level_check.dart).
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
    if (!closed) {
      throw FormatException('Несбалансированные скобки в блоке $prefix');
    }
  }
  return result;
}

int _intField(String block, String name) {
  final m = RegExp('$name:\\s*(\\d+)').firstMatch(block);
  if (m == null) throw FormatException('Нет поля $name');
  return int.parse(m.group(1)!);
}

String? _enumField(String block, String name) =>
    RegExp('$name:\\s*\\w+\\.(\\w+)').firstMatch(block)?.group(1);

/// Содержимое парных скобок, начиная с открывающей на позиции [open].
String _bracketBody(String s, int open) {
  var depth = 0;
  for (var k = open; k < s.length; k++) {
    final ch = s[k];
    if (ch == '[' || ch == '{' || ch == '(') depth++;
    if (ch == ']' || ch == '}' || ch == ')') {
      depth--;
      if (depth == 0) return s.substring(open + 1, k);
    }
  }
  throw FormatException('Несбалансированные скобки');
}

Set<int> _parseWalls(String block, int cols) {
  if (RegExp(r'walls:\s*\{\s*\}').hasMatch(block)) return {};
  final m = RegExp(r'walls:\s*_walls\((\d+),').firstMatch(block);
  if (m == null) throw FormatException('Не удалось разобрать walls');
  if (int.parse(m.group(1)!) != cols) {
    throw FormatException('walls использует другую ширину поля');
  }
  final bracket = block.indexOf('[', m.end);
  final inner = _bracketBody(block, bracket);
  return RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]')
      .allMatches(inner)
      .map((mm) => int.parse(mm.group(2)!) * cols + int.parse(mm.group(1)!))
      .toSet();
}

List<ExtMazeLevel> parseMazeLevels() {
  final directory = Directory.current.path;
  final file = File('$directory${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}games${Platform.pathSeparator}robot_maze'
      '${Platform.pathSeparator}robot_maze_game.dart');
  final source = file.readAsStringSync();

  final blocks = extractCalls(source, 'MazeLevel')
      .where((b) => !b.contains('required this.'))
      .toList();

  final levels = <ExtMazeLevel>[];
  for (final block in blocks) {
    final cols = _intField(block, 'cols');
    final dirName = _enumField(block, 'startDir');
    if (dirName == null) throw FormatException('Нет startDir');

    final keys = <int, int>{};
    for (final m in RegExp(
            r'MazeKey\(\s*(\d+)\s*,\s*(\d+)\s*,\s*MazeColor\.(\w+)\s*\)')
        .allMatches(block)) {
      keys[int.parse(m.group(2)!) * cols + int.parse(m.group(1)!)] =
          _colorIndex(m.group(3)!);
    }

    final doors = <int, int>{};
    for (final m in RegExp(
            r'MazeDoor\(\s*(\d+)\s*,\s*(\d+)\s*,\s*MazeColor\.(\w+)\s*\)')
        .allMatches(block)) {
      doors[int.parse(m.group(2)!) * cols + int.parse(m.group(1)!)] =
          _colorIndex(m.group(3)!);
    }

    final teleports = <int, int>{};
    for (final m in RegExp(
            r'MazeTeleport\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
        .allMatches(block)) {
      final a = int.parse(m.group(2)!) * cols + int.parse(m.group(1)!);
      final b = int.parse(m.group(4)!) * cols + int.parse(m.group(3)!);
      teleports[a] = b;
      teleports[b] = a;
    }

    levels.add(ExtMazeLevel(
      cols: cols,
      rows: _intField(block, 'rows'),
      walls: _parseWalls(block, cols),
      startX: _intField(block, 'startX'),
      startY: _intField(block, 'startY'),
      startDir: _dirFromName(dirName),
      goalX: _intField(block, 'goalX'),
      goalY: _intField(block, 'goalY'),
      keys: keys,
      doors: doors,
      teleports: teleports,
    ));
  }
  return levels;
}

// ---------------------------------------------------------------------------
// BFS по расширенному состоянию «клетка + маска ключей».
// ---------------------------------------------------------------------------

/// Достижима ли цель. Возвращает длину кратчайшего пути в «шагах вперёд»
/// или null, если цель недостижима.
///
/// [treatDoorsAsWalls] = true — вспомогательный режим: двери считаются глухими
/// стенами (проверяем, что без ключей до цели не добраться).
int? solveExt(ExtMazeLevel level, {bool treatDoorsAsWalls = false}) {
  if (level.startCell == level.goalCell) return 0;

  final keyCells = level.keys.keys.toList();
  final maskCount = 1 << keyCells.length;

  int bitAt(int cell) {
    for (var i = 0; i < keyCells.length; i++) {
      if (keyCells[i] == cell) return 1 << i;
    }
    return 0;
  }

  bool doorOpen(int color, int mask) {
    var i = 0;
    for (final c in level.keys.values) {
      if (c == color && (mask & (1 << i)) != 0) return true;
      i++;
    }
    return false;
  }

  int enc(int cell, int mask) => cell * maskCount + mask;

  final visited = <int>{};
  final queue = Queue<(int, int, int)>(); // клетка, маска, шаги
  final startMask = bitAt(level.startCell);
  queue.add((level.startCell, startMask, 0));
  visited.add(enc(level.startCell, startMask));

  while (queue.isNotEmpty) {
    final (cell, mask, steps) = queue.removeFirst();
    final x = cell % level.cols;
    final y = cell ~/ level.cols;

    for (var d = 0; d < 4; d++) {
      final nx = x + _dirDx[d];
      final ny = y + _dirDy[d];
      if (nx < 0 || ny < 0 || nx >= level.cols || ny >= level.rows) continue;
      final target = ny * level.cols + nx;
      if (level.walls.contains(target)) continue;

      final doorColor = level.doors[target];
      if (doorColor != null &&
          (treatDoorsAsWalls || !doorOpen(doorColor, mask))) {
        continue; // дверь закрыта — шаг не выполняется
      }

      var nextMask = mask | bitAt(target);
      var landing = target;

      // Телепорт: робот переносится на парную клетку и «отпускает» вихрь,
      // поэтому повторного срабатывания в этом же шаге нет.
      final partner = level.teleports[target];
      if (partner != null) {
        landing = partner;
        nextMask |= bitAt(partner);
      }

      if (landing == level.goalCell) return steps + 1;
      if (visited.add(enc(landing, nextMask))) {
        queue.add((landing, nextMask, steps + 1));
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Основная проверка.
// ---------------------------------------------------------------------------

void main() {
  stdout.writeln('Проверка уровней «Робот-Лабиринт» (ключи, двери, телепорты)');
  stdout.writeln('─' * 56);

  final problems = <String>[];
  List<ExtMazeLevel> levels;
  try {
    levels = parseMazeLevels();
  } catch (e) {
    stdout.writeln('  ✗ ошибка парсинга: $e');
    exit(1);
  }

  var withExtras = 0;
  var doorLevels = 0;
  var orderMatters = 0;

  for (var i = 0; i < levels.length; i++) {
    final n = i + 1;
    final level = levels[i];
    final levelProblems = <String>[];
    final cells = level.cols * level.rows;

    void checkCell(int cell, String what) {
      if (cell < 0 || cell >= cells) {
        levelProblems.add('$what вне поля ($cell)');
      }
    }

    checkCell(level.startCell, 'старт');
    checkCell(level.goalCell, 'цель');
    for (final c in level.keys.keys) {
      checkCell(c, 'ключ');
    }
    for (final c in level.doors.keys) {
      checkCell(c, 'дверь');
    }
    for (final c in level.teleports.keys) {
      checkCell(c, 'вихрь');
    }

    if (level.walls.contains(level.startCell)) {
      levelProblems.add('старт на стене');
    }
    if (level.walls.contains(level.goalCell)) {
      levelProblems.add('цель на стене');
    }
    for (final c in level.keys.keys) {
      if (level.walls.contains(c)) levelProblems.add('ключ на стене');
    }
    for (final c in level.doors.keys) {
      if (level.walls.contains(c)) levelProblems.add('дверь на стене');
    }
    for (final c in level.teleports.keys) {
      if (level.walls.contains(c)) levelProblems.add('вихрь на стене');
    }
    if (level.keys.containsKey(level.goalCell) ||
        level.doors.containsKey(level.goalCell)) {
      levelProblems.add('цель совпадает с ключом или дверью');
    }
    if (level.keys.containsKey(level.startCell) ||
        level.doors.containsKey(level.startCell)) {
      levelProblems.add('старт совпадает с ключом или дверью');
    }
    for (final c in level.teleports.keys) {
      if (c == level.startCell || c == level.goalCell) {
        levelProblems.add('вихрь на старте или цели');
      }
      if (level.keys.containsKey(c) || level.doors.containsKey(c)) {
        levelProblems.add('вихрь совпадает с ключом или дверью');
      }
    }
    for (final color in level.doors.values) {
      if (!level.keys.values.contains(color)) {
        levelProblems.add('для двери нет ключа цвета ${_colorNames[color]}');
      }
    }

    // --- достижимость ---
    final steps = solveExt(level);
    if (steps == null) levelProblems.add('цель недостижима');

    // Проверяем, что порядок сбора ключей действительно важен: без ключей
    // (двери как стены) до цели не добраться, а с ключами — да.
    if (level.doors.isNotEmpty) {
      final noKeys = solveExt(level, treatDoorsAsWalls: true);
      if (noKeys == null && steps != null) orderMatters++;
    }

    if (level.hasExtras) withExtras++;
    if (level.doors.isNotEmpty) doorLevels++;

    if (levelProblems.isEmpty) {
      final extra = level.hasExtras
          ? '  [ключи:${level.keys.length} двери:${level.doors.length} '
              'вихри:${level.teleports.length ~/ 2}]'
          : '';
      stdout.writeln('  ✓ уровень $n: решаем за $steps шаг(ов)$extra');
    } else {
      stdout.writeln('  ✗ уровень $n: ${levelProblems.join('; ')}');
      problems.addAll(levelProblems.map((p) => 'уровень $n: $p'));
    }
  }

  stdout.writeln('─' * 56);
  if (levels.length != 45) {
    problems.add('всего ${levels.length} уровней, ожидалось 45');
  }
  if (withExtras < 8) {
    problems.add('уровней с новыми элементами $withExtras, ожидалось ≥ 8');
  }

  if (problems.isEmpty) {
    stdout.writeln('  ✓ всего ${levels.length} уровней — все решаемы');
    stdout.writeln('  ✓ с новыми элементами: $withExtras'
        ' (с дверями: $doorLevels, порядок ключей важен: $orderMatters)');
    stdout.writeln('ВСЁ ЗЕЛЁНОЕ ✅');
  } else {
    stdout.writeln('  ✗ проблем: ${problems.length}');
    for (final p in problems) {
      stdout.writeln('      $p');
    }
    exit(1);
  }
}
