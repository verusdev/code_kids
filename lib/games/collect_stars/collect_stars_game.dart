import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import '../grid_board.dart';

/// Описание уровня «Собери звёзды».
class StarsLevel {
  const StarsLevel({
    required this.cols,
    required this.rows,
    required this.walls,
    required this.startX,
    required this.startY,
    required this.starCells,
    required this.hint,
  });

  final int cols;
  final int rows;
  final Set<int> walls;
  final int startX;
  final int startY;
  final List<List<int>> starCells;
  final String hint;
}

Set<int> _walls(int cols, List<List<int>> cells) =>
    cells.map((c) => c[1] * cols + c[0]).toSet();

final List<StarsLevel> _starsLevels = [
  const StarsLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 0,
    startY: 0,
    starCells: [
      [2, 0],
    ],
    hint: 'Двигай персонажа стрелками, чтобы собрать звезду.',
  ),
  const StarsLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 0,
    startY: 0,
    starCells: [
      [2, 0],
      [0, 2],
    ],
    hint: 'Собери все звёзды — их можно собирать в любом порядке.',
  ),
  const StarsLevel(
    cols: 3,
    rows: 3,
    walls: {},
    startX: 1,
    startY: 1,
    starCells: [
      [0, 0],
      [2, 2],
    ],
    hint: 'Планируй путь: сначала к одной звезде, потом к другой.',
  ),
  StarsLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [2, 1],
      [2, 2],
    ]),
    startX: 0,
    startY: 3,
    starCells: [
      [1, 0],
      [3, 3],
    ],
    hint: 'Кирпичи не пропускают — обойди стену по свободным клеткам.',
  ),
  StarsLevel(
    cols: 4,
    rows: 4,
    walls: _walls(4, [
      [1, 1],
      [2, 1],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [0, 3],
      [3, 3],
      [3, 0],
    ],
    hint: 'Пройди уголком: вниз, потом вправо, потом вверх.',
  ),
  StarsLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 1],
      [3, 1],
      [1, 3],
      [3, 3],
    ]),
    startX: 2,
    startY: 2,
    starCells: [
      [0, 0],
      [4, 0],
      [4, 4],
      [0, 4],
    ],
    hint: 'Обойди все четыре звезды по кругу.',
  ),
  StarsLevel(
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
    starCells: [
      [4, 0],
      [0, 4],
    ],
    hint: 'Собери звезду внизу, обойди стену и поднимись к звезде сверху.',
  ),
  StarsLevel(
    cols: 5,
    rows: 5,
    walls: _walls(5, [
      [1, 1],
      [2, 1],
      [3, 1],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [4, 0],
      [0, 4],
    ],
    hint: 'Иди по краю: вправо, вниз, потом влево.',
  ),
  StarsLevel(
    cols: 6,
    rows: 6,
    walls: _walls(6, [
      [2, 2],
      [3, 2],
      [2, 3],
      [3, 3],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [5, 0],
      [5, 5],
      [0, 5],
    ],
    hint: 'Обойди центральный блок по кругу: вправо, вниз, влево.',
  ),
  StarsLevel(
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
    starCells: [
      [2, 2],
      [5, 5],
    ],
    hint: 'Загляни в середину лабиринта за звездой, потом спустись вниз и иди вправо.',
  ),
  StarsLevel(
    cols: 7,
    rows: 7,
    walls: _walls(7, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [3, 1],
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
      [5, 5],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [0, 3],
      [2, 1],
      [4, 5],
      [6, 1],
      [5, 6],
    ],
    hint:
        'Лабиринт-змейка: спустись по левому коридору, поднимись по второму и так до конца.',
  ),
  StarsLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [1, 0],
      [1, 1],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [3, 0],
      [3, 1],
      [3, 2],
      [3, 3],
      [3, 4],
      [3, 5],
      [5, 0],
      [5, 1],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [7, 0],
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [2, 0],
      [4, 2],
      [6, 0],
      [3, 6],
      [7, 7],
    ],
    hint:
        'Гребёнка из коридоров: зайди в каждый коридор за звездой, а потом иди дальше.',
  ),
  StarsLevel(
    cols: 8,
    rows: 8,
    walls: _walls(8, [
      [2, 0],
      [2, 2],
      [2, 3],
      [2, 5],
      [2, 6],
      [2, 7],
      [5, 0],
      [5, 2],
      [5, 3],
      [5, 4],
      [5, 5],
      [5, 6],
      [5, 7],
      [3, 3],
      [4, 3],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [0, 7],
      [3, 2],
      [4, 7],
      [7, 7],
      [7, 3],
    ],
    hint:
        'Комнаты за кирпичами: в правую комнату ведёт одна дверь — придётся вернуться назад.',
  ),
  StarsLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 0],
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
      [2, 5],
      [2, 6],
      [4, 2],
      [4, 3],
      [4, 4],
      [4, 5],
      [4, 6],
      [4, 7],
      [4, 8],
      [6, 0],
      [6, 1],
      [6, 2],
      [6, 3],
      [6, 4],
      [6, 5],
      [6, 6],
      [1, 4],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [1, 2],
      [3, 4],
      [0, 6],
      [5, 7],
      [8, 2],
    ],
    hint:
        'Четыре длинных коридора друг за другом: вниз по левому, вверх по среднему, вниз по правому и снова вверх.',
  ),
  StarsLevel(
    cols: 9,
    rows: 9,
    walls: _walls(9, [
      [2, 0],
      [2, 1],
      [2, 2],
      [2, 3],
      [2, 4],
      [2, 5],
      [2, 6],
      [6, 2],
      [6, 3],
      [6, 4],
      [6, 5],
      [6, 7],
      [6, 8],
      [3, 4],
      [4, 4],
      [5, 4],
      [1, 4],
    ]),
    startX: 0,
    startY: 0,
    starCells: [
      [1, 3],
      [0, 8],
      [4, 5],
      [8, 4],
      [7, 0],
      [4, 1],
    ],
    hint:
        'Самый сложный лабиринт: тупики и узкий проход. Заходи в тупик за звездой и возвращайся назад.',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<StarsLevel> get starsLevels => _starsLevels;

/// Игра «Собери звёзды»: персонаж выполняет программу из блоков-стрелок.
/// Учит составлять линейные программы и планировать маршрут.
class CollectStarsGame extends StatefulWidget {
  const CollectStarsGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<CollectStarsGame> createState() => _CollectStarsGameState();
}

class _CollectStarsGameState extends State<CollectStarsGame> {
  late StarsLevel _level;
  final List<Direction> _program = [];

  int _x = 0;
  int _y = 0;
  late Set<int> _starsLeft;
  bool _running = false;
  bool _won = false;
  int _failedRuns = 0;
  String _status = '';

  static const GameInfo _game = GameInfo(
    id: 'stars',
    title: 'Собери звёзды',
    subtitle: '',
    emoji: '⭐',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _starsLevels[widget.levelIndex % _starsLevels.length];
    _resetLevel();
  }

  void _resetLevel() {
    _x = _level.startX;
    _y = _level.startY;
    _starsLeft = _level.starCells
        .map((c) => c[1] * _level.cols + c[0])
        .toSet();
  }

  void _restart() {
    setState(() {
      _program.clear();
      _failedRuns = 0;
      _won = false;
      _status = '';
      _running = false;
      _resetLevel();
    });
  }

  bool _isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= _level.cols || y >= _level.rows) return true;
    return _level.walls.contains(y * _level.cols + x);
  }

  Future<void> _run() async {
    if (_program.isEmpty || _running || _won) return;
    setState(() {
      _running = true;
      _status = 'Персонаж выполняет программу…';
      _resetLevel();
    });
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    bool crashed = false;
    for (final dir in _program) {
      if (!mounted) return;
      final nx = _x + dir.dx;
      final ny = _y + dir.dy;
      if (_isBlocked(nx, ny)) {
        setState(() => _status = 'Ой! Персонаж упёрся в кирпичи 🧱');
        crashed = true;
      } else {
        setState(() {
          _x = nx;
          _y = ny;
          _starsLeft.remove(ny * _level.cols + nx);
        });
      }
      if (crashed) break;
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
    }

    if (!mounted) return;
    if (_starsLeft.isEmpty) {
      final stars = (3 - _failedRuns).clamp(1, 3);
      setState(() {
        _running = false;
        _won = true;
        _status = 'Все звёзды собраны! ⭐';
      });
      widget.onFinished(stars);
    } else {
      setState(() {
        _running = false;
        _failedRuns++;
        if (!crashed) {
          _status =
              'Осталось звёзд: ${_starsLeft.length}. Добавь ещё команды!';
        }
      });
    }
  }

  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.teal,
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
      child: const FittedBox(
        child: Text('🦊', style: TextStyle(fontSize: 26)),
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
                        for (final k in _starsLeft)
                          BoardSprite(
                            id: 'star_$k',
                            x: k % _level.cols,
                            y: k ~/ _level.cols,
                            child: const FittedBox(
                              child:
                                  Text('⭐', style: TextStyle(fontSize: 26)),
                            ),
                          ),
                        BoardSprite(id: 'hero', x: _x, y: _y, child: _hero()),
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
                maxLevelIndex: _starsLevels.length - 1 - widget.levelIndex,
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
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
      ),
      child: _program.isEmpty
          ? const Center(
              child: Text(
                'Сложи здесь путь из стрелок',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _program.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                return Container(
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_program[i].icon,
                      size: 24, color: AppTheme.teal),
                );
              },
            ),
    );
  }

  Widget _controls(bool canEdit) {
    Widget dirBtn(Direction d) => KidButton(
          label: '',
          icon: d.icon,
          color: AppTheme.teal,
          onPressed: canEdit ? () => setState(() => _program.add(d)) : null,
        );

    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            dirBtn(Direction.up),
            dirBtn(Direction.left),
            dirBtn(Direction.down),
            dirBtn(Direction.right),
            KidButton(
              label: '',
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
                  color: AppTheme.purple,
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
