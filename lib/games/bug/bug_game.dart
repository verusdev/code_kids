import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import '../grid_board.dart';

/// Команда программы робота (как в «Робот-Лабиринте»).
enum BugCommand { forward, turnLeft, turnRight }

extension on BugCommand {
  IconData get icon => switch (this) {
        BugCommand.forward => Icons.arrow_upward_rounded,
        BugCommand.turnLeft => Icons.turn_left_rounded,
        BugCommand.turnRight => Icons.turn_right_rounded,
      };

  String get label => switch (this) {
        BugCommand.forward => 'Вперёд',
        BugCommand.turnLeft => 'Налево',
        BugCommand.turnRight => 'Направо',
      };
}

/// Описание одного уровня игры «Поймай багу».
///
/// [program] — программа с ОДНОЙ ошибкой в команде [bugIndex]; её нужно
/// заменить на [correctFix] из списка вариантов [fixes], после чего робот
/// обязан дойти до флажка.
class BugLevel {
  const BugLevel({
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
    required this.fixes,
    required this.correctFix,
    required this.hint,
    required this.explanation,
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final Direction startDir;
  final int goalX;
  final int goalY;
  final List<BugCommand> program;
  final int bugIndex;
  final List<BugCommand> fixes;
  final BugCommand correctFix;
  final String hint;
  final String explanation;
}

/// Клетки-стены удобно задавать парами (x, y).
Set<int> _walls(int cols, List<List<int>> cells) =>
    cells.map((c) => c[1] * cols + c[0]).toSet();

/// Акцентный цвет игры (из общей палитры темы).
Color get _bugColor => AppTheme.gameColors['bug'] ?? AppTheme.teal;

final List<BugLevel> _bugLevels = [
  // 1. Самый простой: два «вперёд», баг — лишний поворот в начале.
  const BugLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 0,
    startY: 2,
    startDir: Direction.up,
    goalX: 0,
    goalY: 0,
    program: [BugCommand.turnLeft, BugCommand.forward],
    bugIndex: 0,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Запусти программу и следи за роботом: где он свернул не туда?',
    explanation:
        'Команда «налево» развернула робота в сторону стены — а надо было '
        'просто идти прямо к флажку.',
  ),
  // 2. Робот ушёл вверх вместо поворота вбок.
  BugLevel(
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
    program: [BugCommand.forward, BugCommand.forward, BugCommand.forward],
    bugIndex: 0,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnRight,
    hint: 'Робот ушёл вверх, а флажок вбок. Подумай, какая команда делает '
        'поворот.',
    explanation:
        'Первой командой было «вперёд», и робот ушёл вверх мимо флажка. '
        'Нужно сначала повернуть направо — и тогда два «вперёд» приведут '
        'к цели.',
  ),
  // 3. Робот свернул налево и врезался в стену.
  BugLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [2, 0],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 0,
    goalY: 3,
    program: [
      BugCommand.turnRight,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 1,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Посмотри, в какую сторону робот смотрит после первой команды.',
    explanation:
        'После поворота робот смотрел вниз, но команда «налево» развернула '
        'его влево — прямо к стене. Нужно было идти вперёд вниз по клетке.',
  ),
  // 4. Поворот не в ту сторону у края поля.
  BugLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [2, 1],
    ]),
    startX: 0,
    startY: 2,
    startDir: Direction.up,
    goalX: 1,
    goalY: 0,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
    ],
    bugIndex: 2,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnRight,
    hint: 'После двух «вперёд» робот оказался не у флажка. Что было не так?',
    explanation:
        'Поворот «налево» развернул робота к краю поля. Чтобы свернуть '
        'к флажку справа, нужен был поворот «направо».',
  ),
  // 5. Ошибка в повороте после спуска: робот уходит за край.
  BugLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [1, 0],
      [2, 0],
      [3, 0],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.right,
    goalX: 3,
    goalY: 1,
    program: [
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 2,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnLeft,
    hint: 'Робот смотрит вниз. Какой поворот уведёт его от флажка?',
    explanation:
        'Спустившись вниз, робот смотрел вниз: поворот «налево» разворачивает '
        'его вправо, к флажку. А «направо» увело робота за левый край поля.',
  ),
  // 6. Первый тупик: стены-домики, ошибка в повороте после спуска.
  BugLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [2, 1],
      [2, 2],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 3,
    goalY: 3,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 3,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnLeft,
    hint: 'Спуск вниз — верный путь. А вот поворот робот сделал не в ту '
        'сторону.',
    explanation:
        'Робот смотрел вниз: поворот «налево» вёл его вправо, по нижнему '
        'ряду прямо к флажку. Поворот «направо» развернул робота к стене.',
  ),
  // 7. Длинный проход вверх и поворот не в ту сторону.
  BugLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 2],
      [2, 2],
      [3, 2],
    ]),
    startX: 0,
    startY: 3,
    startDir: Direction.up,
    goalX: 4,
    goalY: 0,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 3,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnRight,
    hint: 'В верхнем ряду робот свернул не туда. С какой стороны флажок?',
    explanation:
        'Дойдя до верха, робот повернул налево — и ушёл за край поля. '
        'Флажок ждал справа: нужен был поворот «направо».',
  ),
  // 8. Робот вдруг пошёл вверх посреди нижнего ряда.
  BugLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [2, 1],
      [2, 2],
      [2, 3],
    ]),
    startX: 0,
    startY: 1,
    startDir: Direction.down,
    goalX: 4,
    goalY: 4,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 4,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'В нижнем ряду робот вдруг пошёл вверх. Что за команда?',
    explanation:
        'В нижнем ряду робот повернул налево вместо движения вперёд — и пошёл '
        'вверх мимо флажка. В этом месте нужна была команда «вперёд».',
  ),
  // 9. Лишний поворот в вертикальном коридоре.
  BugLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [2, 2],
    ]),
    startX: 0,
    startY: 2,
    startDir: Direction.right,
    goalX: 4,
    goalY: 0,
    program: [
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 3,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Робот пошёл вверх и упёрся в край. Может, здесь вообще не нужен '
        'поворот?',
    explanation:
        'Идя вверх, робот повернул налево вместо того, чтобы продолжать идти '
        'прямо, — и упёрся в край поля. Нужна была команда «вперёд».',
  ),
  // 10. Ошибка в повороте посреди длинного коридора.
  BugLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [1, 0],
      [1, 1],
      [1, 2],
      [4, 2],
      [4, 3],
      [4, 4],
    ]),
    startX: 0,
    startY: 0,
    startDir: Direction.down,
    goalX: 3,
    goalY: 5,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 6,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'В коридоре робот свернул вверх. Какая команда мешает идти прямо?',
    explanation:
        'Идя вправо по коридору, робот повернул налево вместо движения '
        'вперёд — и пошёл вверх, в тупик. Здесь нужна была команда «вперёд».',
  ),
  // 11. Обход препятствия: ошибка в начале длинного ряда.
  BugLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 3],
      [2, 3],
      [3, 3],
    ]),
    startX: 0,
    startY: 4,
    startDir: Direction.up,
    goalX: 4,
    goalY: 4,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 4,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Длинный ряд — идеальный момент идти прямо. Но робот свернул.',
    explanation:
        'В середине длинного ряда робот повернул налево вместо движения '
        'вперёд — и пошёл вверх мимо флажка. Нужно было продолжать идти '
        'прямо.',
  ),
  // 12. Робот проехал низ и ушёл вверх вместо движения вперёд.
  BugLevel(
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
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 6,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Робот проехал низ и ушёл вверх. Флажок был впереди.',
    explanation:
        'Проехав нижний ряд, робот повернул налево — и пошёл вверх, мимо '
        'флажка. Нужно было продолжать идти вперёд.',
  ),
  // 13. Лесенка: ошибка в повороте посреди узора.
  BugLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [0, 0],
      [4, 2],
      [4, 4],
    ]),
    startX: 0,
    startY: 4,
    startDir: Direction.up,
    goalX: 4,
    goalY: 0,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 5,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.turnLeft,
    hint: 'Посмотри, куда ведёт каждый поворот: вверх или назад?',
    explanation:
        'Поворот «направо» развернул робота вниз, назад к началу. После '
        'движения вбок нужен был поворот «налево» — вверх, к флажку.',
  ),
  // 14. Длинный коридор вверх: ошибка в первом «вперёд» после поворота.
  BugLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [1, 2],
      [1, 3],
      [1, 4],
      [3, 2],
      [4, 2],
      [5, 2],
    ]),
    startX: 0,
    startY: 5,
    startDir: Direction.up,
    goalX: 5,
    goalY: 0,
    program: [
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 7,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'После поворота робот шёл не в ту сторону. Куда смотрит робот?',
    explanation:
        'После поворота робот смотрел вверх и ушёл за край поля. После '
        'команды «направо» нужны были пять «вперёд» — прямо к флажку.',
  ),
  // 15. Финал: вход в домик-кольцо, ошибка в первом «вперёд» у края.
  BugLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [2, 1],
      [3, 1],
      [4, 1],
      [4, 2],
      [4, 3],
      [3, 3],
      [2, 3],
    ]),
    startX: 3,
    startY: 5,
    startDir: Direction.up,
    goalX: 2,
    goalY: 2,
    program: [
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.turnLeft,
      BugCommand.forward,
      BugCommand.forward,
      BugCommand.turnRight,
      BugCommand.forward,
      BugCommand.forward,
    ],
    bugIndex: 5,
    fixes: [BugCommand.forward, BugCommand.turnLeft, BugCommand.turnRight],
    correctFix: BugCommand.forward,
    hint: 'Край поля — опасное место. Что робот сделал не так, идя вверх?',
    explanation:
        'Идя вверх по краю, робот повернул налево вместо движения вперёд — '
        'и ушёл за край поля. Здесь нужна была команда «вперёд».',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<BugLevel> get bugLevels => _bugLevels;

/// Игра «Поймай багу»: ребёнок ищет ошибку в готовой программе робота —
/// сначала запускает её и смотрит траекторию, потом выбирает сломанную
/// команду и заменяет её верной. Учит отладке: читать программу шаг за шагом.
class BugGame extends StatefulWidget {
  const BugGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<BugGame> createState() => _BugGameState();
}

/// Фазы игры: ждём → робот бежит → выбираем команду → меняем → победа.
enum _Phase { idle, running, pick, fix, explain }

class _BugGameState extends State<BugGame> {
  late BugLevel _level;
  late List<BugCommand> _program;

  _Phase _phase = _Phase.idle;
  int _x = 0;
  int _y = 0;
  Direction _dir = Direction.up;
  int? _highlight;
  bool _crashedLastRun = false;
  int _mistakes = 0;
  bool _usedHint = false;
  bool _showWin = false;
  String _message = '';

  static const GameInfo _game = GameInfo(
    id: 'bug',
    title: 'Поймай багу',
    subtitle: '',
    emoji: '🐛',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _bugLevels[widget.levelIndex % _bugLevels.length];
    _program = List.of(_level.program);
    _resetRobot();
    _message = _level.hint;
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

  int get _stars =>
      _usedHint ? 1 : (_mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1));

  void _restart() {
    setState(() {
      _program = List.of(_level.program);
      _phase = _Phase.idle;
      _mistakes = 0;
      _usedHint = false;
      _showWin = false;
      _highlight = null;
      _crashedLastRun = false;
      _message = _level.hint;
      _resetRobot();
    });
  }

  /// Анимация выполнения текущей программы: подсвечиваем команды по очереди.
  Future<void> _animateRun() async {
    setState(() {
      _phase = _Phase.running;
      _crashedLastRun = false;
      _highlight = null;
      _resetRobot();
    });
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _program.length; i++) {
      if (!mounted) return;
      setState(() => _highlight = i);
      await Future.delayed(const Duration(milliseconds: 330));
      if (!mounted) return;
      final cmd = _program[i];
      if (cmd == BugCommand.forward) {
        final nx = _x + _dir.dx;
        final ny = _y + _dir.dy;
        if (_isBlocked(nx, ny)) {
          setState(() {
            _crashedLastRun = true;
            _highlight = null;
          });
          break;
        }
        setState(() {
          _x = nx;
          _y = ny;
        });
      } else {
        setState(() {
          _dir = cmd == BugCommand.turnLeft ? _dir.turnLeft : _dir.turnRight;
        });
      }
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
  }

  Future<void> _run() async {
    if (_phase == _Phase.running || _phase == _Phase.explain) return;
    await _animateRun();
    if (!mounted) return;
    final reached = _x == _level.goalX && _y == _level.goalY;
    setState(() {
      _highlight = null;
      if (reached) {
        // По условиям уровней это не должно случиться до починки — но если
        // робот и так добрался, засчитываем победу честно.
        _phase = _Phase.explain;
        _message = _level.explanation;
      } else {
        _phase = _Phase.pick;
        _message = _crashedLastRun
            ? 'Ой! Робот врезался в стену 🧱 Нажми на команду, в которой баг.'
            : 'Робот не добрался до флажка 🚩 Нажми на команду, в которой баг.';
      }
    });
    if (reached) widget.onFinished(_stars);
  }

  void _pickCommand(int index) {
    if (_phase != _Phase.pick) return;
    if (index == _level.bugIndex) {
      setState(() {
        _phase = _Phase.fix;
        _message = 'Верно! Какой командой её заменить?';
      });
    } else {
      setState(() {
        _mistakes++;
        _message = 'Эта команда выглядит верно. Проверь шаги ещё раз 🙂';
      });
    }
  }

  Future<void> _applyFix(BugCommand fix) async {
    if (_phase != _Phase.fix) return;
    if (fix == _level.correctFix) {
      setState(() => _program[_level.bugIndex] = fix);
      await _animateRun();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.explain;
        _message = _level.explanation;
      });
      widget.onFinished(_stars);
    } else {
      setState(() {
        _mistakes++;
        _message = 'Кажется, не эта команда. Попробуй ещё раз!';
      });
    }
  }

  void _useHint() {
    if (_usedHint || _phase == _Phase.explain) return;
    setState(() {
      _usedHint = true;
      _message =
          'Подсказка: посмотри на команду №${_level.bugIndex + 1} — после неё '
          'робот свернул не туда.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: _message, color: _bugColor),
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
                        BoardSprite(
                          id: 'robot',
                          x: _x,
                          y: _y,
                          child: _robot(),
                        ),
                      ],
                    ),
                  ),
                ),
                _programBar(),
                _controls(),
                const SizedBox(height: 12),
              ],
            ),
            if (_showWin)
              WinOverlay(
                game: _game,
                stars: _stars,
                maxLevelIndex: _bugLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
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
        color: _crashedLastRun ? Colors.red : _bugColor,
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
          child: Text(
            _crashedLastRun ? '💥' : '🤖',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }

  /// Список команд программы: подсвечивает текущую и позволяет выбрать баг.
  Widget _programBar() {
    final accent = _bugColor;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < _program.length; i++)
            GestureDetector(
              onTap: _phase == _Phase.pick ? () => _pickCommand(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _highlight == i
                      ? accent.withValues(alpha: 0.45)
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _highlight == i ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                    Icon(_program[i].icon, size: 20, color: accent),
                    if (i == _level.bugIndex &&
                        _program[i] == _level.correctFix)
                      const Text('✅', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls() {
    final accent = _bugColor;
    switch (_phase) {
      case _Phase.idle:
      case _Phase.pick:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: KidButton(
                  label: _phase == _Phase.idle ? 'Проверить' : 'Ещё раз',
                  icon: Icons.play_arrow_rounded,
                  color: accent,
                  expand: true,
                  onPressed: _run,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KidButton(
                  label: 'Подсказка',
                  emoji: '💡',
                  color: AppTheme.orange,
                  expand: true,
                  onPressed: _usedHint ? null : _useHint,
                ),
              ),
            ],
          ),
        );
      case _Phase.running:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              'Робот выполняет программу…',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _Phase.fix:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final cmd in _level.fixes)
                KidButton(
                  label: cmd.label,
                  icon: cmd.icon,
                  color: accent,
                  onPressed: () => _applyFix(cmd),
                ),
            ],
          ),
        );
      case _Phase.explain:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: KidButton(
            label: 'Забрать звёзды ⭐',
            icon: Icons.star_rounded,
            color: AppTheme.yellow,
            expand: true,
            onPressed: () => setState(() => _showWin = true),
          ),
        );
    }
  }
}
