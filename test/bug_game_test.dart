// Проверка игры «Поймай багу»: структура 15 уровней и симуляция программы
// робота. Программа с багом не должна доходить до флажка, а исправленная —
// должна, причём из всех предложенных вариантов вести к цели обязана только
// верная команда (иначе задание неоднозначно).
//
// Симуляция повторяет `_animateRun` из lib/games/bug/bug_game.dart: робот
// поворачивается или идёт вперёд; «вперёд» в стену или за край поля — авария
// и остановка выполнения.
import 'package:code_kids/games/bug/bug_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// Итог прогона программы: где робот остановился и была ли авария.
class _Run {
  const _Run(this.x, this.y, this.crashed);

  final int x;
  final int y;
  final bool crashed;
}

/// Выполняет программу так же, как игра при кнопке «Проверить».
_Run _runProgram(BugLevel level, List<BugCommand> program) {
  var x = level.startX;
  var y = level.startY;
  var dir = level.startDir;

  bool blocked(int cx, int cy) {
    if (cx < 0 || cy < 0 || cx >= level.cols || cy >= level.rows) return true;
    return level.walls.contains(cy * level.cols + cx);
  }

  for (final cmd in program) {
    if (cmd == BugCommand.forward) {
      final nx = x + dir.dx;
      final ny = y + dir.dy;
      if (blocked(nx, ny)) return _Run(x, y, true);
      x = nx;
      y = ny;
    } else {
      dir = cmd == BugCommand.turnLeft ? dir.turnLeft : dir.turnRight;
    }
  }
  return _Run(x, y, false);
}

/// Программа уровня, в которой багованная команда заменена на [fix].
List<BugCommand> _withFix(BugLevel level, BugCommand fix) {
  final program = List<BugCommand>.of(level.program);
  program[level.bugIndex] = fix;
  return program;
}

bool _reachedGoal(BugLevel level, _Run run) =>
    !run.crashed && run.x == level.goalX && run.y == level.goalY;

void main() {
  test('в игре «Поймай багу» 15 уровней', () {
    expect(bugLevels.length, 15);
  });

  test('структура каждого уровня корректна', () {
    for (var i = 0; i < bugLevels.length; i++) {
      final level = bugLevels[i];
      final n = i + 1;

      expect(level.program, isNotEmpty, reason: 'уровень $n: пустая программа');
      expect(
        level.bugIndex,
        inInclusiveRange(0, level.program.length - 1),
        reason: 'уровень $n: bugIndex вне программы',
      );
      expect(level.fixes, contains(level.correctFix),
          reason: 'уровень $n: верной команды нет среди вариантов');
      expect(level.fixes.length, greaterThanOrEqualTo(2),
          reason: 'уровень $n: слишком мало вариантов');
      expect(
        level.program[level.bugIndex] == level.correctFix,
        isFalse,
        reason: 'уровень $n: «багованная» команда уже и есть верная',
      );
      expect(
        level.startX == level.goalX && level.startY == level.goalY,
        isFalse,
        reason: 'уровень $n: робот стартует прямо на флажке',
      );
      expect(level.hint, isNotEmpty, reason: 'уровень $n: пустая подсказка');
      expect(level.explanation, isNotEmpty, reason: 'уровень $n: пустое пояснение');

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
    }
  });

  test('программа с багом не доходит до флажка', () {
    for (var i = 0; i < bugLevels.length; i++) {
      final level = bugLevels[i];
      final run = _runProgram(level, level.program);
      expect(
        run.x == level.goalX && run.y == level.goalY,
        isFalse,
        reason: 'уровень ${i + 1}: программа с багом всё равно доходит '
            'до флажка — искать баг бессмысленно',
      );
    }
  });

  test('исправленная программа доходит до флажка без аварии', () {
    for (var i = 0; i < bugLevels.length; i++) {
      final level = bugLevels[i];
      final run = _runProgram(level, _withFix(level, level.correctFix));
      expect(run.crashed, isFalse,
          reason: 'уровень ${i + 1}: верное решение врезается в стену');
      expect(
        run.x == level.goalX && run.y == level.goalY,
        isTrue,
        reason: 'уровень ${i + 1}: верное решение не доходит до флажка',
      );
    }
  });

  test('из всех вариантов к флажку ведёт только верная команда', () {
    for (var i = 0; i < bugLevels.length; i++) {
      final level = bugLevels[i];
      final reaching = <BugCommand>{};
      for (final fix in level.fixes) {
        if (_reachedGoal(level, _runProgram(level, _withFix(level, fix)))) {
          reaching.add(fix);
        }
      }
      expect(reaching, {level.correctFix},
          reason: 'уровень ${i + 1}: до флажка ведут несколько вариантов '
              '(${reaching.map((c) => c.name).join(', ')}) — задание '
              'неоднозначно');
    }
  });
}
