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

  static const GameInfo _game = GameInfo(
    id: 'maze',
    title: 'Робот-Лабиринт',
    subtitle: '',
    emoji: '🤖',
    levelCount: 15,
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
  }

  bool _isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= _level.cols || y >= _level.rows) return true;
    return _level.walls.contains(y * _level.cols + x);
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
            setState(() {
              _x = nx;
              _y = ny;
            });
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
