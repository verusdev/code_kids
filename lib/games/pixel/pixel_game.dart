import 'dart:async';

import 'package:flutter/material.dart';

import '../../blocks/block_model.dart';
import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/block_editor.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';

/// Команды кисточки в игре «Пиксель-арт».
const BlockCommandDef kPaint = BlockCommandDef(
  id: 'paint',
  icon: Icons.brush_rounded,
  label: 'Закрась',
);
const BlockCommandDef kRight = BlockCommandDef(
  id: 'right',
  icon: Icons.arrow_forward_rounded,
  label: 'Вправо',
);
const BlockCommandDef kDown = BlockCommandDef(
  id: 'down',
  icon: Icons.arrow_downward_rounded,
  label: 'Вниз',
);
const BlockCommandDef kLeft = BlockCommandDef(
  id: 'left',
  icon: Icons.arrow_back_rounded,
  label: 'Влево',
);
const BlockCommandDef kUp = BlockCommandDef(
  id: 'up',
  icon: Icons.arrow_upward_rounded,
  label: 'Вверх',
);

/// Доступные блоки пиксель-арта (условия нет — только команды и цикл).
const List<BlockCommandDef> kPixelBlocks = [kPaint, kRight, kDown, kLeft, kUp];

/// Один шаг симуляции (состояние поля после команды).
class PixelStep {
  const PixelStep({
    required this.painted,
    required this.cursor,
    required this.commandId,
  });

  final Set<int> painted;
  final int cursor;
  final String commandId;
}

/// Результат симуляции программы.
class PixelSim {
  PixelSim({
    required this.steps,
    required this.finalPainted,
    required this.hitLimit,
  });

  final List<PixelStep> steps;
  final Set<int> finalPainted;
  final bool hitLimit;
}

/// Выполняет программу на поле пиксель-арта и возвращает все шаги.
///
/// Кисточка стартует в (0, 0). Команды «Вправо»/«Вниз»/… выходят за границы
/// поля — команда просто пропускается (кисточка остаётся на месте).
PixelSim simulatePixel(
  List<BlockNode> program,
  int cols,
  int rows, {
  int maxSteps = kBlockMaxSteps,
}) {
  final painted = <int>{};
  final steps = <PixelStep>[];
  var x = 0;
  var y = 0;
  var count = 0;
  var hitLimit = false;

  void rec(List<BlockNode> nodes) {
    for (final node in nodes) {
      if (hitLimit) return;
      if (count >= maxSteps) {
        hitLimit = true;
        return;
      }
      switch (node) {
        case CommandBlock():
          count++;
          switch (node.def.id) {
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
          steps.add(PixelStep(
            painted: Set.of(painted),
            cursor: y * cols + x,
            commandId: node.def.id,
          ));
        case RepeatBlock():
          for (var i = 0; i < node.times; i++) {
            rec(node.body);
            if (hitLimit) return;
          }
        case IfBlock():
          rec(node.body);
      }
    }
  }

  rec(program);
  return PixelSim(steps: steps, finalPainted: painted, hitLimit: hitLimit);
}

/// Описание уровня пиксель-арта.
class PixelLevel {
  const PixelLevel({
    required this.cols,
    required this.rows,
    required this.target,
    required this.hint,
  });

  final int cols;
  final int rows;

  /// Клетки, которые нужно закрасить (индекс = x + y * cols).
  final Set<int> target;

  final String hint;
}

/// Уровни пиксель-арта (15 штук, от простого к сложному).
const List<PixelLevel> _pixelLevels = [
  PixelLevel(
    cols: 2,
    rows: 2,
    target: {0},
    hint: 'Просто нажми «Закрась» и запусти программу.',
  ),
  PixelLevel(
    cols: 6,
    rows: 3,
    target: {6, 7, 8, 9, 10, 11},
    hint: 'Линия из шести клеток — помоги циклом: «Закрась, вправо».',
  ),
  PixelLevel(
    cols: 3,
    rows: 6,
    target: {1, 4, 7, 10, 13, 16},
    hint: 'Теперь столбик: «Закрась, вниз» и повтори!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 3, 4, 9, 14, 19, 24},
    hint: 'Уголок: сначала закрась верхнюю линию, потом правый столбик.',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 6, 12, 18, 24},
    hint: 'Диагональ: цикл «Закрась, вправо, вниз».',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 5, 6, 7, 10, 11, 12},
    hint: 'Квадрат из девяти клеток: внутри цикла ещё один цикл!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 5, 10, 15, 20, 2, 7, 12, 17, 22},
    hint: 'Два столбика: закрась первый циклом, вернись и закрась второй.',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 2, 4, 10, 12, 14, 20, 22, 24},
    hint: 'Шашечки: закрашивай клетку, пропускай одну. Дважды повторить!',
  ),
  PixelLevel(
    cols: 6,
    rows: 6,
    target: {0, 1, 6, 7, 12, 13, 18, 19},
    hint: 'Прямоугольник 2 на 4: вложенные циклы снова в деле!',
  ),
  PixelLevel(
    cols: 5,
    rows: 5,
    target: {0, 1, 2, 3, 4, 5, 9, 10, 14, 15, 19, 20, 21, 22, 23, 24},
    hint: 'Рамка вокруг всего поля: четыре цикла — верх, вниз по стенке, низ и обратно.',
  ),
  // 11: буква «П» — верхняя линия и две ножки.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {0, 1, 2, 3, 4, 5, 6, 7, 13, 14, 20, 21, 27, 28, 34, 35, 41, 42, 48},
    hint: 'Буква «П»: сначала нарисуй верхнюю линию, потом спустись вниз по правой ножке и поднимись по левой.',
  ),
  // 12: шахматный узор — клетки через одну «змейкой».
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39,
      41, 43, 45, 47,
    },
    hint: 'Шахматный узор: закрашивай через клетку. Строки идут «змейкой» — то вправо, то влево.',
  ),
  // 13: сердечко — широкие строки, к низу сужается.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      1, 2, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
      23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 37, 38, 39, 45,
    },
    hint: 'Сердечко: две «ямочки» сверху, потом целые широкие строки, а книзу оно сужается до одной клетки.',
  ),
  // 14: ёлочка — треугольник из строк разной длины и ствол.
  PixelLevel(
    cols: 7,
    rows: 7,
    target: {
      3, 9, 10, 11, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 31, 38, 45,
    },
    hint: 'Ёлочка: каждая строка треугольника шире предыдущей, а в самом низу — маленький ствол.',
  ),
  // 15: две параллельные диагонали.
  PixelLevel(
    cols: 9,
    rows: 9,
    target: {0, 1, 10, 11, 20, 21, 30, 31, 40, 41, 50, 51, 60, 61, 70, 71, 80},
    hint: 'Две параллельные диагонали: нарисуй одну по диагонали, вернись назад и нарисуй вторую рядом.',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих проходимость).
List<PixelLevel> get pixelLevels => _pixelLevels;

/// Игра «Пиксель-арт»: рисуем картинку командами из блоков.
class PixelGame extends StatefulWidget {
  const PixelGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<PixelGame> createState() => _PixelGameState();
}

class _PixelGameState extends State<PixelGame> {
  late PixelLevel _level;
  final List<BlockNode> _program = [];

  Set<int> _painted = {};
  int _cursor = 0;
  bool _running = false;
  bool _won = false;
  int _failedRuns = 0;
  String _status = '';

  static const GameInfo _game = GameInfo(
    id: 'pixel',
    title: 'Пиксель-арт',
    subtitle: '',
    emoji: '🎨',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _pixelLevels[widget.levelIndex % _pixelLevels.length];
  }

  void _restart() {
    setState(() {
      _program.clear();
      _painted = {};
      _cursor = 0;
      _won = false;
      _running = false;
      _failedRuns = 0;
      _status = '';
    });
  }

  Future<void> _run() async {
    if (_program.isEmpty || _running || _won) return;
    setState(() {
      _running = true;
      _status = 'Кисточка рисует…';
      _painted = {};
      _cursor = 0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final sim = simulatePixel(_program, _level.cols, _level.rows);
    if (sim.hitLimit) {
      setState(() {
        _running = false;
        _failedRuns++;
        _status = 'Программа очень длинная — упрости её 🙂';
      });
      return;
    }
    for (final step in sim.steps) {
      if (!mounted) return;
      setState(() {
        _painted = step.painted;
        _cursor = step.cursor;
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted) return;

    final ok = _painted.length == _level.target.length &&
        _painted.containsAll(_level.target);
    if (ok) {
      final stars = (3 - _failedRuns).clamp(1, 3);
      setState(() {
        _running = false;
        _won = true;
        _status = 'Готово! Картинка получилась! 🎨';
      });
      widget.onFinished(stars);
    } else {
      final missing = _level.target.difference(_painted).length;
      final extra = _painted.difference(_level.target).length;
      setState(() {
        _running = false;
        _failedRuns++;
        if (missing > 0 && extra > 0) {
          _status = 'Почти! Не хватает $missing, лишних $extra.';
        } else if (missing > 0) {
          _status = 'Не хватает $missing клеток — добавь блоков!';
        } else {
          _status = 'Лишних $extra клеток — убери их из программы.';
        }
      });
    }
  }

  Widget _board() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _level.cols,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _level.cols * _level.rows,
          itemBuilder: (context, i) => _cell(i),
        ),
      ),
    );
  }

  Widget _cell(int index) {
    final inTarget = _level.target.contains(index);
    final painted = _painted.contains(index);
    final isCursor = _cursor == index && _running;
    Color color = Colors.grey.shade100;
    if (painted) {
      color = AppTheme.purple;
    } else if (inTarget) {
      color = AppTheme.sky.withValues(alpha: 0.22);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isCursor
            ? Border.all(color: AppTheme.orange, width: 3)
            : null,
      ),
      child: Center(
        child: painted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : (isCursor
                ? Icon(Icons.brush_rounded, color: AppTheme.orange, size: 16)
                : null),
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
                  flex: 6,
                  child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _board(),
                  )),
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
                maxLevelIndex: _pixelLevels.length - 1 - widget.levelIndex,
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
              commands: kPixelBlocks,
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
                  ? () => setState(() {
                        _program.clear();
                        _painted = {};
                        _cursor = 0;
                        _status = '';
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}