import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import 'memory_levels.dart';

/// Игра «Найди пару» — тренировка памяти.
class MemoryGame extends StatefulWidget {
  const MemoryGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late MemoryLevel _level;
  late List<_CardState> _cards;
  int _firstIndex = -1;
  int _secondIndex = -1;
  bool _isChecking = false;
  int _moves = 0;
  int _matchedPairs = 0;
  bool _won = false;
  int _stars = 0;

  static const GameInfo _game = GameInfo(
    id: 'memory',
    title: 'Найди пару',
    subtitle: 'Запомни и открой пары',
    emoji: '🧠',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant MemoryGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelIndex != widget.levelIndex) {
      setState(_setup);
    }
  }

  void _setup() {
    _level = memoryLevels[widget.levelIndex % memoryLevels.length];
    final deck = <_CardState>[];
    for (int p = 0; p < _level.pairs; p++) {
      final emoji = _level.emojiSet[p];
      deck.add(_CardState(pairId: p, emoji: emoji));
      deck.add(_CardState(pairId: p, emoji: emoji));
    }
    // Детерминированное перемешивание: одна и та же раскладка для уровня.
    int s = widget.levelIndex * 131542391 + 7;
    for (int i = deck.length - 1; i > 0; i--) {
      s ^= (s << 13);
      s ^= (s >> 17);
      s ^= (s << 5);
      final r = s.abs() % (i + 1);
      final tmp = deck[i];
      deck[i] = deck[r];
      deck[r] = tmp;
    }
    _cards = deck;
    _firstIndex = -1;
    _secondIndex = -1;
    _isChecking = false;
    _moves = 0;
    _matchedPairs = 0;
    _won = false;
    _stars = 0;
  }

  void _restart() {
    setState(_setup);
  }

  void _onCardTap(int index) {
    if (_won || _isChecking) return;
    final card = _cards[index];
    if (card.isMatched || card.isFaceUp) return;

    setState(() {
      _cards[index] = card.copyWith(isFaceUp: true);
      if (_firstIndex == -1) {
        _firstIndex = index;
        return;
      }
      _secondIndex = index;
      _moves++;
      _isChecking = true;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final firstCard = _cards[_firstIndex];
      final secondCard = _cards[_secondIndex];
      final match = firstCard.pairId == secondCard.pairId;
      if (match) {
        setState(() {
          _cards[_firstIndex] = firstCard.copyWith(
            isMatched: true,
            isFaceUp: true,
          );
          _cards[_secondIndex] = secondCard.copyWith(
            isMatched: true,
            isFaceUp: true,
          );
          _matchedPairs++;
          _firstIndex = -1;
          _secondIndex = -1;
          _isChecking = false;
          if (_matchedPairs == _level.pairs) {
            _won = true;
            _stars = _computeStars();
            widget.onFinished(_stars);
          }
        });
      } else {
        setState(() {
          _cards[_firstIndex] = firstCard.copyWith(isFaceUp: false);
          _cards[_secondIndex] = secondCard.copyWith(isFaceUp: false);
          _firstIndex = -1;
          _secondIndex = -1;
          _isChecking = false;
        });
      }
    });
  }

  int _computeStars() {
    if (_moves <= _level.idealMoves) return 3;
    if (_moves <= _level.stars2Moves) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final totalCards = level.columns * level.rows;
    final cardSize = totalCards <= 6
        ? 92.0
        : totalCards <= 9
        ? 86.0
        : totalCards <= 12
        ? 80.0
        : totalCards <= 16
        ? 74.0
        : 68.0;

    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: level.hint, color: AppTheme.purple),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(
                        label: 'Пары',
                        value: '$_matchedPairs / ${level.pairs}',
                      ),
                      _StatChip(label: 'Ходы', value: '$_moves'),
                      _StatChip(label: 'Идеал', value: '${level.idealMoves}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: level.columns * (cardSize + 10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cards.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: level.columns,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            return _MemoryCardView(
                              size: cardSize,
                              emoji: card.emoji,
                              isFaceUp: card.isFaceUp || card.isMatched,
                              isMatched: card.isMatched,
                              onTap: () => _onCardTap(index),
                            );
                          },
                        ),
                      ),
                    ),
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
                maxLevelIndex: memoryLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }
}

class _CardState {
  final int pairId;
  final String emoji;
  final bool isFaceUp;
  final bool isMatched;

  const _CardState({
    required this.pairId,
    required this.emoji,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  _CardState copyWith({
    int? pairId,
    String? emoji,
    bool? isFaceUp,
    bool? isMatched,
  }) {
    return _CardState(
      pairId: pairId ?? this.pairId,
      emoji: emoji ?? this.emoji,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

class _MemoryCardView extends StatelessWidget {
  const _MemoryCardView({
    required this.size,
    required this.emoji,
    required this.isFaceUp,
    required this.isMatched,
    required this.onTap,
  });

  final double size;
  final String emoji;
  final bool isFaceUp;
  final bool isMatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isMatched
        ? theme.colorScheme.secondaryContainer
        : isFaceUp
        ? theme.colorScheme.surface
        : AppTheme.purple.withValues(alpha: 0.85);
    final border = Border.all(
      color: isMatched ? theme.colorScheme.secondary : AppTheme.purple,
      width: 3,
    );

    return SizedBox(
      width: size,
      height: size,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: isFaceUp
                ? Text(
                    emoji,
                    key: ValueKey(emoji),
                    style: TextStyle(fontSize: size * 0.42),
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: const ValueKey('back'),
                    size: size * 0.36,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
