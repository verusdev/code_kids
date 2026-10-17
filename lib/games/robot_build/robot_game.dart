import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import 'robot_levels.dart';

/// Акцентный цвет игры «Собери робота» (золотисто-янтарный).
const Color kRobotColor = Color(0xFFFFB300);

/// Игра «Собери робота из модулей».
///
/// Ребёнок выбирает модуль и ставит его в слот корпуса. Когда все слоты
/// заняты верно, робот «выполняет задание» — и уровень пройден.
/// Учит системному мышлению: какие части нужны, чтобы система заработала.
class RobotGame extends StatefulWidget {
  const RobotGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<RobotGame> createState() => _RobotGameState();
}

class _RobotGameState extends State<RobotGame> {
  late RobotLevel _level;

  /// Что стоит в слотах: индекс слота → тип модуля.
  final Map<int, RobotKind> _placed = {};

  /// Выбранный в лотке модуль (готов к установке).
  RobotKind? _selected;

  int _mistakes = 0;
  int? _wrongSlot;
  bool _usedHint = false;
  bool _running = false;
  bool _won = false;
  String _message = '';

  static const GameInfo _game = GameInfo(
    id: 'robot',
    title: 'Собери робота',
    subtitle: '',
    emoji: '🤖',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = robotLevels[widget.levelIndex % robotLevels.length];
    _message = _level.hint;
  }

  int get _stars => _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);

  List<RobotKind> get _tray =>
      _level.pool.where((k) => !_placed.containsValue(k)).toList();

  void _restart() {
    setState(() {
      _placed.clear();
      _selected = null;
      _mistakes = 0;
      _wrongSlot = null;
      _usedHint = false;
      _running = false;
      _won = false;
      _message = _level.hint;
    });
  }

  void _selectModule(RobotKind kind) {
    if (_won || _running) return;
    SoundService.tap();
    setState(() {
      _selected = _selected == kind ? null : kind;
    });
  }

  void _tapSlot(int index) {
    if (_won || _running) return;
    SoundService.tap();
    setState(() {
      _wrongSlot = null;
      if (_selected != null) {
        _placed[index] = _selected!;
        _selected = null;
      } else if (_placed.containsKey(index)) {
        _placed.remove(index);
      } else {
        _message = 'Сначала выбери модуль внизу, а потом нажми на слот 🙂';
      }
    });
  }

  void _check() {
    if (_won || _running) return;
    if (_level.isSolved(_placed)) {
      _runTask();
      return;
    }

    SoundService.wrong();
    _mistakes++;

    // Сначала ищем слот с неправильным модулем, потом — пустой слот.
    int? wrong;
    for (var i = 0; i < _level.slots.length; i++) {
      final placed = _placed[i];
      if (placed != null && placed != _level.slots[i].accepts) {
        wrong = i;
        break;
      }
    }

    String message;
    int? highlight;
    if (wrong != null) {
      highlight = wrong;
      message = 'Модуль в слоте «${_level.slots[wrong].label}» тут не '
          'работает. Замени его на другой 🤔';
    } else {
      var empty = 0;
      for (var i = 0; i < _level.slots.length; i++) {
        if (_placed[i] == null) {
          empty = i;
          break;
        }
      }
      message = 'Слот «${_level.slots[empty].label}» ещё пустой. '
          'Поставь туда модуль 🙂';
    }

    setState(() {
      _wrongSlot = highlight;
      _selected = null;
      _message = message;
    });
  }

  Future<void> _runTask() async {
    setState(() {
      _running = true;
      _selected = null;
      _wrongSlot = null;
      _message = 'Робот выполняет задание… ⚙️';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final stars = _stars;
    setState(() {
      _running = false;
      _won = true;
      _message = _level.explanation;
    });
    widget.onFinished(stars);
  }

  void _useHint() {
    if (_usedHint || _won || _running) return;
    var extra = '';
    for (var i = 0; i < _level.slots.length; i++) {
      if (_placed[i] != _level.slots[i].accepts) {
        extra = ' Слот «${_level.slots[i].label}»: '
            '${_level.slots[i].why}';
        break;
      }
    }
    setState(() {
      _usedHint = true;
      _message = '💡 ${_level.hint}$extra';
    });
  }

  @override
  Widget build(BuildContext context) {
    final showScene = _running || _won;
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: _message, color: kRobotColor),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _taskBanner(),
                        const SizedBox(height: 16),
                        if (showScene)
                          _scene()
                        else ...[
                          _robotBody(),
                          const SizedBox(height: 18),
                          _traySection(),
                        ],
                      ],
                    ),
                  ),
                ),
                _controls(enabled: !showScene),
                const SizedBox(height: 12),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: _stars,
                maxLevelIndex: robotLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _taskBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: kRobotColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(_level.taskEmoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Задание робота:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _level.task,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _robotBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kRobotColor.withValues(alpha: 0.45), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 52)),
          const Text(
            'Корпус робота',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _level.slots.length; i++)
                    _slotTile(i, tileWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _slotTile(int index, double width) {
    final slot = _level.slots[index];
    final placed = _placed[index];
    final wrong = _wrongSlot == index;
    final border = wrong ? Colors.red : kRobotColor;

    return GestureDetector(
      onTap: () => _tapSlot(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 102,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: wrong
              ? Colors.red.shade50
              : (placed != null
                  ? kRobotColor.withValues(alpha: 0.10)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: border.withValues(alpha: placed != null || wrong ? 0.9 : 0.5),
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              placed?.emoji ?? '➕',
              style: TextStyle(
                fontSize: placed != null ? 30 : 26,
                color: placed != null ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slot.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(
              placed?.label ?? 'пусто',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _traySection() {
    final tray = _tray;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Модули для сборки:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (tray.isEmpty)
          const Text(
            'Все модули уже на своих местах. Нажми «Проверить» ▶',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [for (final kind in tray) _moduleTile(kind)],
          ),
      ],
    );
  }

  Widget _moduleTile(RobotKind kind) {
    final selected = _selected == kind;
    return GestureDetector(
      onTap: () => _selectModule(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 98,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? kRobotColor.withValues(alpha: 0.20)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? kRobotColor : Colors.black.withValues(alpha: 0.08),
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(kind.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              kind.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scene() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kRobotColor.withValues(alpha: 0.45), width: 3),
      ),
      child: Column(
        children: [
          const Text(
            'Выполняю задание! ⚙️',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeInOut,
                  builder: (context, t, _) {
                    final x = t * (constraints.maxWidth - 64);
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _level.taskEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        Positioned(
                          left: x,
                          top: 18,
                          child: const Text(
                            '🤖',
                            style: TextStyle(fontSize: 44),
                          ),
                        ),
                        if (t > 0.75)
                          const Positioned(
                            right: 2,
                            top: 0,
                            child: Text('✅', style: TextStyle(fontSize: 24)),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Задание: ${_level.task}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _controls({required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: KidButton(
              label: 'Проверить',
              icon: Icons.play_arrow_rounded,
              color: kRobotColor,
              expand: true,
              onPressed: enabled ? _check : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: KidButton(
              label: 'Подсказка',
              emoji: '💡',
              color: AppTheme.orange,
              expand: true,
              onPressed: (enabled && !_usedHint) ? _useHint : null,
            ),
          ),
        ],
      ),
    );
  }
}
