import 'package:code_kids/blocks/block_model.dart';
import 'package:code_kids/games/collect_stars/collect_stars_game.dart';
import 'package:code_kids/games/blocks/blocks_game.dart';
import 'package:code_kids/games/causes/causes_game.dart';
import 'package:code_kids/games/pixel/pixel_game.dart';
import 'package:code_kids/games/odd_one_out/odd_one_out_game.dart';
import 'package:code_kids/games/parts/parts_game.dart';
import 'package:code_kids/games/pattern/pattern_game.dart';
import 'package:code_kids/games/robot_maze/robot_maze_game.dart';
import 'package:code_kids/games/rules/rules_game.dart';
import 'package:code_kids/games/steps_order/steps_order_game.dart';
import 'package:code_kids/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Сколько уровней минимум должно быть в каждом тренажёре.
const int kMinLevels = 15;

/// Проходим ли лабиринт: обход состояний (клетка + направление робота).
bool mazeSolvable(MazeLevel level) {
  bool isWall(int x, int y) => level.walls.contains(y * level.cols + x);
  final dirs = Direction.values;
  final start = dirs.indexOf(level.startDir);

  final visited = <String>{'${level.startX},${level.startY},$start'};
  final queue = <List<int>>[
    [level.startX, level.startY, start],
  ];

  while (queue.isNotEmpty) {
    final state = queue.removeAt(0);
    final x = state[0];
    final y = state[1];
    final d = state[2];
    if (x == level.goalX && y == level.goalY) return true;

    final dir = dirs[d];
    for (final turned in [dir.turnLeft, dir.turnRight]) {
      final nd = dirs.indexOf(turned);
      if (visited.add('$x,$y,$nd')) queue.add([x, y, nd]);
    }
    final nx = x + dir.dx;
    final ny = y + dir.dy;
    if (nx < 0 || nx >= level.cols || ny < 0 || ny >= level.rows) continue;
    if (isWall(nx, ny)) continue;
    if (visited.add('$nx,$ny,$d')) queue.add([nx, ny, d]);
  }
  return false;
}

/// Можно ли собрать все звёзды: обход состояний (клетка + набор собранного).
bool starsSolvable(StarsLevel level) {
  bool isWall(int x, int y) => level.walls.contains(y * level.cols + x);

  int starsAt(int x, int y) {
    var bits = 0;
    for (var i = 0; i < level.starCells.length; i++) {
      if (level.starCells[i][0] == x && level.starCells[i][1] == y) {
        bits |= 1 << i;
      }
    }
    return bits;
  }

  final full = (1 << level.starCells.length) - 1;
  final startMask = starsAt(level.startX, level.startY);
  final visited = <String>{'${level.startX},${level.startY},$startMask'};
  final queue = <List<int>>[
    [level.startX, level.startY, startMask],
  ];

  while (queue.isNotEmpty) {
    final state = queue.removeAt(0);
    final x = state[0];
    final y = state[1];
    final mask = state[2];
    if (mask == full) return true;

    for (final dir in Direction.values) {
      final nx = x + dir.dx;
      final ny = y + dir.dy;
      if (nx < 0 || nx >= level.cols || ny < 0 || ny >= level.rows) continue;
      if (isWall(nx, ny)) continue;
      final nextMask = mask | starsAt(nx, ny);
      if (visited.add('$nx,$ny,$nextMask')) queue.add([nx, ny, nextMask]);
    }
  }
  return false;
}

void main() {
  group('Количество уровней', () {
    test('у каждой игры минимум $kMinLevels уровней', () {
      expect(mazeLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(starsLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(patternLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(oddLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(stepsLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(blockLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(pixelLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(partsLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(causesLevels.length, greaterThanOrEqualTo(kMinLevels));
      expect(rulesLevels.length, greaterThanOrEqualTo(kMinLevels));
    });

    test('реестр kGames совпадает с числом уровней', () {
      expect(gameById('maze').levelCount, mazeLevels.length);
      expect(gameById('stars').levelCount, starsLevels.length);
      expect(gameById('pattern').levelCount, patternLevels.length);
      expect(gameById('odd').levelCount, oddLevels.length);
      expect(gameById('steps').levelCount, stepsLevels.length);
      expect(gameById('blocks').levelCount, blockLevels.length);
      expect(gameById('pixel').levelCount, pixelLevels.length);
    });

    test('реестр kSystemGames совпадает с числом уровней', () {
      expect(kSystemGames.length, 3);
      expect(gameById('parts').levelCount, partsLevels.length);
      expect(gameById('causes').levelCount, causesLevels.length);
      expect(gameById('rules').levelCount, rulesLevels.length);
    });
  });

  group('Робот-Лабиринт', () {
    test('каждый уровень проходим', () {
      for (var i = 0; i < mazeLevels.length; i++) {
        final level = mazeLevels[i];
        expect(
          level.walls.contains(level.startY * level.cols + level.startX),
          isFalse,
          reason: 'уровень ${i + 1}: робот стоит на стене',
        );
        expect(
          level.walls.contains(level.goalY * level.cols + level.goalX),
          isFalse,
          reason: 'уровень ${i + 1}: флажок стоит на стене',
        );
        expect(mazeSolvable(level), isTrue,
            reason: 'уровень ${i + 1} не проходим');
      }
    });
  });

  group('Программируй блоками', () {
    test('каждый уровень проходим', () {
      for (var i = 0; i < blockLevels.length; i++) {
        final level = blockLevels[i];
        expect(
          level.walls.contains(level.startY * level.cols + level.startX),
          isFalse,
          reason: 'уровень ${i + 1}: робот стоит на стене',
        );
        expect(
          level.walls.contains(level.goalY * level.cols + level.goalX),
          isFalse,
          reason: 'уровень ${i + 1}: флажок стоит на стене',
        );
        expect(mazeSolvable(level), isTrue,
            reason: 'уровень ${i + 1} не проходим');
      }
    });
  });

  group('Пиксель-арт', () {
    test('цели в пределах поля и структура', () {
      for (var i = 0; i < pixelLevels.length; i++) {
        final level = pixelLevels[i];
        expect(level.target, isNotEmpty, reason: 'уровень ${i + 1}: пустая цель');
        for (final cell in level.target) {
          expect(cell, inInclusiveRange(0, level.cols * level.rows - 1),
              reason: 'уровень ${i + 1}: клетка вне поля');
        }
      }
    });

    test('каждый уровень проходим программой из блоков', () {
      final solutions = <List<BlockNode>>[
        // 1: просто закрасить стартовую клетку.
        [CommandBlock(kPaint)],
        // 2: вниз, потом цикл: закрась и вправо.
        [
          CommandBlock(kDown),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
        ],
        // 3: вправо, потом цикл: закрась и вниз.
        [
          CommandBlock(kRight),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kPaint), CommandBlock(kDown)],
          ),
        ],
        // 4: уголок — верхняя линия и правый столбик.
        [
          RepeatBlock(
            times: 5,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kDown), CommandBlock(kPaint)],
          ),
        ],
        // 5: диагональ.
        [
          RepeatBlock(
            times: 5,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kDown),
            ],
          ),
        ],
        // 6: квадрат 3x3 — вложенные циклы.
        [
          RepeatBlock(
            times: 3,
            body: [
              RepeatBlock(
                times: 3,
                body: [CommandBlock(kPaint), CommandBlock(kRight)],
              ),
              CommandBlock(kDown),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
        ],
        // 7: два столбика — спуститься, вернуться и подняться.
        [
          RepeatBlock(
            times: 5,
            body: [CommandBlock(kPaint), CommandBlock(kDown)],
          ),
          CommandBlock(kRight),
          CommandBlock(kRight),
          RepeatBlock(
            times: 5,
            body: [CommandBlock(kPaint), CommandBlock(kUp)],
          ),
        ],
        // 8: шашечки (чётные клетки) — вложенные циклы со сдвигом на 2.
        [
          RepeatBlock(
            times: 3,
            body: [
              RepeatBlock(
                times: 3,
                body: [
                  CommandBlock(kPaint),
                  CommandBlock(kRight),
                  CommandBlock(kRight),
                ],
              ),
              CommandBlock(kDown),
              CommandBlock(kDown),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
        ],
        // 9: прямоугольник 2x4 — вложенные циклы.
        [
          RepeatBlock(
            times: 4,
            body: [
              RepeatBlock(
                times: 2,
                body: [CommandBlock(kPaint), CommandBlock(kRight)],
              ),
              CommandBlock(kDown),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
        ],
        // 10: рамка вокруг поля — четыре цикла.
        [
          RepeatBlock(
            times: 5,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kDown), CommandBlock(kPaint)],
          ),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kLeft), CommandBlock(kPaint)],
          ),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kUp), CommandBlock(kPaint)],
          ),
        ],
        // 11: буква «П» — верхняя линия, правый столбик, возврат и левый столбик.
        [
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kDown), CommandBlock(kPaint)],
          ),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kLeft)],
          ),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 5,
            body: [CommandBlock(kUp), CommandBlock(kPaint)],
          ),
        ],
        // 12: шахматный узор 7x7 — «змейка» с шагом в две клетки.
        [
          CommandBlock(kRight),
          RepeatBlock(
            times: 3,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kRight),
            ],
          ),
          CommandBlock(kDown),
          RepeatBlock(
            times: 4,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
          CommandBlock(kDown),
          CommandBlock(kRight),
          RepeatBlock(
            times: 3,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kRight),
            ],
          ),
          CommandBlock(kDown),
          RepeatBlock(
            times: 4,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
          CommandBlock(kDown),
          CommandBlock(kRight),
          RepeatBlock(
            times: 3,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kRight),
            ],
          ),
          CommandBlock(kDown),
          RepeatBlock(
            times: 4,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kLeft),
              CommandBlock(kLeft),
            ],
          ),
          CommandBlock(kDown),
          CommandBlock(kRight),
          RepeatBlock(
            times: 3,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kRight),
            ],
          ),
        ],
        // 13: сердечко — заполняем строками, к низу сужается.
        [
          CommandBlock(kRight),
          RepeatBlock(
            times: 2,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
          CommandBlock(kRight),
          RepeatBlock(
            times: 2,
            body: [CommandBlock(kPaint), CommandBlock(kRight)],
          ),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kLeft), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kRight), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kLeft), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kRight),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kRight), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kLeft),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 2,
            body: [CommandBlock(kLeft), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kRight),
          CommandBlock(kPaint),
        ],
        // 14: ёлочка — треугольник из строк разной длины и ствол.
        [
          CommandBlock(kRight),
          CommandBlock(kRight),
          CommandBlock(kRight),
          CommandBlock(kPaint),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          CommandBlock(kLeft),
          CommandBlock(kPaint),
          CommandBlock(kRight),
          CommandBlock(kRight),
          CommandBlock(kPaint),
          CommandBlock(kDown),
          CommandBlock(kRight),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 4,
            body: [CommandBlock(kLeft), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          CommandBlock(kLeft),
          CommandBlock(kPaint),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kRight), CommandBlock(kPaint)],
          ),
          CommandBlock(kDown),
          CommandBlock(kLeft),
          CommandBlock(kLeft),
          CommandBlock(kLeft),
          CommandBlock(kPaint),
          CommandBlock(kDown),
          CommandBlock(kPaint),
          CommandBlock(kDown),
          CommandBlock(kPaint),
        ],
        // 15: две параллельные диагонали 9x9 — рисуем, возвращаемся, рисуем рядом.
        [
          RepeatBlock(
            times: 6,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kDown),
            ],
          ),
          RepeatBlock(
            times: 3,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kDown),
            ],
          ),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kLeft)],
          ),
          CommandBlock(kLeft),
          RepeatBlock(
            times: 6,
            body: [CommandBlock(kUp)],
          ),
          RepeatBlock(
            times: 2,
            body: [CommandBlock(kUp)],
          ),
          RepeatBlock(
            times: 6,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kDown),
            ],
          ),
          RepeatBlock(
            times: 2,
            body: [
              CommandBlock(kPaint),
              CommandBlock(kRight),
              CommandBlock(kDown),
            ],
          ),
        ],
      ];
      expect(solutions.length, pixelLevels.length);
      for (var i = 0; i < pixelLevels.length; i++) {
        final level = pixelLevels[i];
        final sim = simulatePixel(solutions[i], level.cols, level.rows);
        expect(
          sim.finalPainted,
          level.target,
          reason: 'уровень ${i + 1}: программа-решение не рисует нужную цель',
        );
        expect(sim.hitLimit, isFalse,
            reason: 'уровень ${i + 1}: программа слишком длинная');
      }
    });
  });

  group('Собери звёзды', () {
    test('на каждом уровне можно собрать все звёзды', () {
      for (var i = 0; i < starsLevels.length; i++) {
        final level = starsLevels[i];
        expect(level.starCells, isNotEmpty,
            reason: 'уровень ${i + 1}: нет звёзд');
        for (final star in level.starCells) {
          expect(
            level.walls.contains(star[1] * level.cols + star[0]),
            isFalse,
            reason: 'уровень ${i + 1}: звезда на стене',
          );
        }
        expect(starsSolvable(level), isTrue,
            reason: 'уровень ${i + 1}: звёзды недостижимы');
      }
    });
  });

  group('Найди закономерность', () {
    test('варианты ответа корректны', () {
      for (var i = 0; i < patternLevels.length; i++) {
        final level = patternLevels[i];
        expect(level.sequence, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.options.length, greaterThanOrEqualTo(2),
            reason: 'уровень ${i + 1}');
        expect(level.correctIndex, inInclusiveRange(0, level.options.length - 1),
            reason: 'уровень ${i + 1}: неверный correctIndex');
        expect(level.explanation, isNotEmpty, reason: 'уровень ${i + 1}');
      }
    });
  });

  group('Лишний элемент', () {
    test('лишний элемент корректно задан', () {
      for (var i = 0; i < oddLevels.length; i++) {
        final level = oddLevels[i];
        expect(level.items.length, greaterThanOrEqualTo(3),
            reason: 'уровень ${i + 1}');
        expect(level.oddIndex, inInclusiveRange(0, level.items.length - 1),
            reason: 'уровень ${i + 1}: неверный oddIndex');
        expect(level.explanation, isNotEmpty, reason: 'уровень ${i + 1}');
      }
    });
  });

  group('Порядок действий', () {
    test('в каждом уровне есть шаги и название', () {
      for (var i = 0; i < stepsLevels.length; i++) {
        final level = stepsLevels[i];
        expect(level.title, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.steps.length, greaterThanOrEqualTo(3),
            reason: 'уровень ${i + 1}');
        for (final step in level.steps) {
          expect(step.text, isNotEmpty, reason: 'уровень ${i + 1}');
          expect(step.emoji, isNotEmpty, reason: 'уровень ${i + 1}');
        }
      }
    });
  });

  group('Системное мышление: части и целое', () {
    test('пропавшая часть совпадает с верным ответом', () {
      for (var i = 0; i < partsLevels.length; i++) {
        final level = partsLevels[i];
        expect(level.title, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.parts.length, greaterThanOrEqualTo(3),
            reason: 'уровень ${i + 1}');
        expect(level.missingIndex, inInclusiveRange(0, level.parts.length - 1),
            reason: 'уровень ${i + 1}: неверный missingIndex');
        expect(level.options.length, greaterThanOrEqualTo(2),
            reason: 'уровень ${i + 1}');
        expect(level.correctIndex, inInclusiveRange(0, level.options.length - 1),
            reason: 'уровень ${i + 1}: неверный correctIndex');
        final missing = level.parts[level.missingIndex];
        final answer = level.options[level.correctIndex];
        expect(answer.label, missing.label,
            reason: 'уровень ${i + 1}: верный ответ не та часть, что пропала');
        expect(level.explanation, isNotEmpty, reason: 'уровень ${i + 1}');
      }
    });
  });

  group('Системное мышление: цепочка причин', () {
    test('у каждого уровня есть ситуация и варианты', () {
      for (var i = 0; i < causesLevels.length; i++) {
        final level = causesLevels[i];
        expect(level.prompt, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.options.length, greaterThanOrEqualTo(2),
            reason: 'уровень ${i + 1}');
        expect(level.correctIndex, inInclusiveRange(0, level.options.length - 1),
            reason: 'уровень ${i + 1}: неверный correctIndex');
        expect(level.explanation, isNotEmpty, reason: 'уровень ${i + 1}');
      }
    });
  });

  group('Системное мышление: умные правила', () {
    test('у каждого уровня есть правило, показание и варианты', () {
      for (var i = 0; i < rulesLevels.length; i++) {
        final level = rulesLevels[i];
        expect(level.deviceName, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.rule, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.reading, isNotEmpty, reason: 'уровень ${i + 1}');
        expect(level.options.length, greaterThanOrEqualTo(2),
            reason: 'уровень ${i + 1}');
        expect(level.correctIndex, inInclusiveRange(0, level.options.length - 1),
            reason: 'уровень ${i + 1}: неверный correctIndex');
        expect(level.explanation, isNotEmpty, reason: 'уровень ${i + 1}');
      }
    });
  });
}
