import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import 'hanoi_levels.dart';

/// Игра «Ханойская башня» — перекладывание дисков по правилам.
class HanoiGame extends StatefulWidget {
  const HanoiGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<HanoiGame> createState() => _HanoiGameState();
}

class _HanoiGameState extends State<HanoiGame> {
  late HanoiLevel _level;
  late List<List<int>> _pegs; // стержни: [низ ... верх]
  int? _selectedPeg;
  int _moves = 0;
  bool _won = false;
  int _stars = 0;

  static const GameInfo _game = GameInfo(
    id: 'hanoi',
    title: 'Ханойская башня',
    subtitle: 'Переложи башню по правилам',
    emoji: '🗼',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant HanoiGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelIndex != widget.levelIndex) {
      setState(_setup);
    }
  }

  void _setup() {
    _level = hanoiLevels[widget.levelIndex % hanoiLevels.length];
    _pegs = List.generate(_level.pegs, (_) => <int>[]);
    // На первом стержне — башня: снизу большой диск (disks), сверху маленький (1).
    for (int d = _level.disks; d >= 1; d--) {
      _pegs[0].add(d);
    }
    _selectedPeg = null;
    _moves = 0;
    _won = false;
    _stars = 0;
  }

  void _restart() {
    setState(_setup);
  }

  void _onPegTap(int index) {
    if (_won) return;
    if (_selectedPeg == null) {
      if (_pegs[index].isEmpty) return;
      setState(() => _selectedPeg = index);
      return;
    }

    if (_selectedPeg == index) {
      setState(() => _selectedPeg = null);
      return;
    }

    final from = _selectedPeg!;
    final src = _pegs[from];
    final dst = _pegs[index];
    final disk = src.last;
    if (dst.isNotEmpty && dst.last < disk) {
      // Нельзя класть больший диск на меньший — мягкая подсказка.
      setState(() => _selectedPeg = null);
      return;
    }

    setState(() {
      src.removeLast();
      dst.add(disk);
      _moves++;
      _selectedPeg = null;
      if (_pegs.last.length == _level.disks) {
        _won = true;
        _stars = _computeStars();
        widget.onFinished(_stars);
      }
    });
  }

  int _computeStars() {
    final optimal = _level.optimalMoves;
    if (_moves <= optimal) return 3;
    if (_moves <= optimal + (optimal ~/ 4) + 2) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final diskCount = _level.disks;
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: _level.hint, color: AppTheme.sky),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(label: 'Диски', value: '$diskCount'),
                      _StatChip(label: 'Ходы', value: '$_moves'),
                      _StatChip(
                        label: 'Минимум',
                        value: '${_level.optimalMoves}',
                      ),
                      if (_level.moveLimit > 0)
                        _StatChip(
                          label: 'Предел',
                          value: '${_level.moveLimit}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxDiskWidth =
                          (constraints.maxWidth / _level.pegs) * 0.86;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (int i = 0; i < _level.pegs; i++)
                              Expanded(
                                child: _PegColumn(
                                  index: i,
                                  disks: _pegs[i],
                                  diskCount: diskCount,
                                  maxDiskWidth: maxDiskWidth,
                                  selected: _selectedPeg == i,
                                  onTap: () => _onPegTap(i),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: KidButton(
                    label: 'Начать заново',
                    icon: Icons.refresh_rounded,
                    onPressed: _restart,
                  ),
                ),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: _stars,
                maxLevelIndex: hanoiLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }
}

/// Колонна-стержень с дисками.
class _PegColumn extends StatelessWidget {
  const _PegColumn({
    required this.index,
    required this.disks,
    required this.diskCount,
    required this.maxDiskWidth,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final List<int> disks;
  final int diskCount;
  final double maxDiskWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.sky.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.sky : Colors.transparent,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (int i = disks.length - 1; i >= 0; i--) _disk(disks[i]),
            const SizedBox(height: 4),
            // Основание стержня.
            Container(
              height: 10,
              width: maxDiskWidth,
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disk(int size) {
    final width = maxDiskWidth * (size / diskCount).clamp(0.28, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        width: width,
        height: 26,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _diskColor(size),
              _diskColor(size).withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$size',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Color _diskColor(int size) {
    const palette = [
      Color(0xFFE84393),
      Color(0xFFFF9F43),
      Color(0xFFFDCB6E),
      Color(0xFF00B894),
      Color(0xFF0984E3),
      Color(0xFF6C5CE7),
      Color(0xFFB84CE3),
      Color(0xFFE17055),
      Color(0xFF2DBE60),
      Color(0xFF3742FA),
    ];
    return palette[(size - 1) % palette.length];
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(width: 5),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
