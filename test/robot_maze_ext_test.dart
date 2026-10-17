// Расширенная проверка «Робота-Лабиринта»: новые элементы уровней 31–45
// (ключи, двери, телепорты) и проходимость всех 45 уровней.
//
// Алгоритм обхода скопирован из эталонной утилиты
// `tool/maze_ext_check.dart` (файл только для чтения), но работает напрямую
// с реальными данными уровней (MazeLevel/MazeKey/MazeDoor/MazeTeleport).
import 'dart:collection';

import 'package:code_kids/games/robot_maze/robot_maze_game.dart';
import 'package:flutter_test/flutter_test.dart';

// Направления движения: индекс → смещение (совпадает с Direction в игре).
const List<int> _dirDx = [0, 1, 0, -1];
const List<int> _dirDy = [-1, 0, 1, 0];

/// Достижима ли цель. Обход в ширину по состоянию «клетка + маска собранных
/// ключей». Возвращает длину кратчайшего пути в «шагах вперёд» или null.
///
/// Повороты в игре бесплатны, поэтому направление робота не входит в
/// состояние — из каждой клетки доступны все четыре хода.
///
/// [treatDoorsAsWalls] = true — вспомогательный режим: двери считаются глухими
/// стенами (проверяем, что без ключей до цели не добраться).
int? solveExt(MazeLevel level, {bool treatDoorsAsWalls = false}) {
  final startCell = level.startY * level.cols + level.startX;
  final goalCell = level.goalY * level.cols + level.goalX;
  if (startCell == goalCell) return 0;

  final keyCells = [for (final k in level.keys) k.y * level.cols + k.x];
  final keyColors = [for (final k in level.keys) k.color];
  final maskCount = 1 << keyCells.length;

  int bitAt(int cell) {
    for (var i = 0; i < keyCells.length; i++) {
      if (keyCells[i] == cell) return 1 << i;
    }
    return 0;
  }

  bool doorOpen(MazeColor color, int mask) {
    for (var i = 0; i < keyColors.length; i++) {
      if (keyColors[i] == color && (mask & (1 << i)) != 0) return true;
    }
    return false;
  }

  final doors = <int, MazeColor>{
    for (final d in level.doors) d.y * level.cols + d.x: d.color,
  };
  final teleports = <int, int>{};
  for (final t in level.teleports) {
    final a = t.ay * level.cols + t.ax;
    final b = t.by * level.cols + t.bx;
    teleports[a] = b;
    teleports[b] = a;
  }

  int enc(int cell, int mask) => cell * maskCount + mask;

  final visited = <int>{};
  final queue = Queue<(int, int, int)>(); // клетка, маска, шаги
  final startMask = bitAt(startCell);
  queue.add((startCell, startMask, 0));
  visited.add(enc(startCell, startMask));

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

      final doorColor = doors[target];
      if (doorColor != null &&
          (treatDoorsAsWalls || !doorOpen(doorColor, mask))) {
        continue; // дверь закрыта — шаг не выполняется
      }

      var nextMask = mask | bitAt(target);
      var landing = target;

      // Телепорт: робот переносится на парную клетку и «гасит» вихрь,
      // поэтому повторного срабатывания в этом же шаге нет.
      final partner = teleports[target];
      if (partner != null) {
        landing = partner;
        nextMask |= bitAt(partner);
      }

      if (landing == goalCell) return steps + 1;
      if (visited.add(enc(landing, nextMask))) {
        queue.add((landing, nextMask, steps + 1));
      }
    }
  }
  return null;
}

void main() {
  test('в лабиринте 45 уровней', () {
    expect(mazeLevels.length, 45);
  });

  test('структура уровней корректна и каждый уровень проходим', () {
    for (var i = 0; i < mazeLevels.length; i++) {
      final level = mazeLevels[i];
      final n = i + 1;
      final cells = level.cols * level.rows;
      int cellOf(int x, int y) => y * level.cols + x;

      expect(level.walls.contains(cellOf(level.startX, level.startY)), isFalse,
          reason: 'уровень $n: робот стоит на стене');
      expect(level.walls.contains(cellOf(level.goalX, level.goalY)), isFalse,
          reason: 'уровень $n: флажок стоит на стене');

      for (final k in level.keys) {
        expect(cellOf(k.x, k.y), inInclusiveRange(0, cells - 1),
            reason: 'уровень $n: ключ вне поля');
        expect(level.walls.contains(cellOf(k.x, k.y)), isFalse,
            reason: 'уровень $n: ключ на стене');
      }
      for (final d in level.doors) {
        expect(cellOf(d.x, d.y), inInclusiveRange(0, cells - 1),
            reason: 'уровень $n: дверь вне поля');
        expect(level.walls.contains(cellOf(d.x, d.y)), isFalse,
            reason: 'уровень $n: дверь на стене');
        expect(level.keys.any((k) => k.color == d.color), isTrue,
            reason: 'уровень $n: для двери «${d.color}» нет ключа');
      }
      for (final t in level.teleports) {
        expect(cellOf(t.ax, t.ay), inInclusiveRange(0, cells - 1),
            reason: 'уровень $n: вихрь вне поля');
        expect(cellOf(t.bx, t.by), inInclusiveRange(0, cells - 1),
            reason: 'уровень $n: вихрь вне поля');
        expect(level.walls.contains(cellOf(t.ax, t.ay)), isFalse,
            reason: 'уровень $n: вихрь на стене');
        expect(level.walls.contains(cellOf(t.bx, t.by)), isFalse,
            reason: 'уровень $n: вихрь на стене');
      }

      expect(solveExt(level), isNotNull,
          reason: 'уровень $n не проходим (цель недостижима)');
    }
  });

  test('двери требуют ключ: без ключей до цели не добраться', () {
    var doorLevels = 0;
    for (var i = 0; i < mazeLevels.length; i++) {
      final level = mazeLevels[i];
      if (level.doors.isEmpty) continue;
      doorLevels++;
      expect(solveExt(level), isNotNull, reason: 'уровень ${i + 1}');
      expect(
        solveExt(level, treatDoorsAsWalls: true),
        isNull,
        reason: 'уровень ${i + 1}: цель достижима, даже если считать двери '
            'стенами — сценарий с ключами не имеет смысла',
      );
    }
    expect(doorLevels, greaterThanOrEqualTo(1),
        reason: 'должны быть уровни с дверями');
  });

  test('уровней с новыми элементами не меньше восьми и они осмысленны', () {
    var withExtras = 0;
    for (final level in mazeLevels) {
      final hasExtras =
          level.keys.isNotEmpty || level.doors.isNotEmpty || level.teleports.isNotEmpty;
      if (!hasExtras) continue;
      withExtras++;
      final startCell = level.startY * level.cols + level.startX;
      final goalCell = level.goalY * level.cols + level.goalX;
      // Ключ/дверь/вихрь не стоят на старте или цели.
      for (final k in level.keys) {
        final c = k.y * level.cols + k.x;
        expect(c == startCell, isFalse, reason: 'ключ на старте');
        expect(c == goalCell, isFalse, reason: 'ключ на цели');
      }
      for (final d in level.doors) {
        final c = d.y * level.cols + d.x;
        expect(c == startCell, isFalse, reason: 'дверь на старте');
        expect(c == goalCell, isFalse, reason: 'дверь на цели');
      }
      for (final t in level.teleports) {
        final a = t.ay * level.cols + t.ax;
        final b = t.by * level.cols + t.bx;
        expect(a == startCell || b == startCell, isFalse, reason: 'вихрь на старте');
        expect(a == goalCell || b == goalCell, isFalse, reason: 'вихрь на цели');
      }
    }
    expect(withExtras, greaterThanOrEqualTo(8));
  });
}
