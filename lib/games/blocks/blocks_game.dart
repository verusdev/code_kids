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
];

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
    levelCount: 15,
  );

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
              conditionLabel: 'Если впереди стена',
              enabled: canEdit,
              onChanged: () => setState(() {}),
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
