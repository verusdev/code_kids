import 'package:flutter/material.dart';

import '../games/game_definition.dart';
import '../models/game_models.dart';
import '../services/progress_service.dart';
import '../widgets/star_row.dart';

/// Экран выбора уровня внутри одной игры.
///
/// Два режима: «Сетка» (классические плитки) и «Карта» (путь-путешествие
/// по уровням с роботом на текущем уровне и замком в финале).
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.game});

  final GameInfo game;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  bool _mapView = false;

  GameInfo get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('${game.emoji} ${game.title}'),
        actions: [
          IconButton(
            tooltip: _mapView ? 'Показать сеткой' : 'Показать картой',
            icon: Icon(_mapView ? Icons.grid_view_rounded : Icons.map_rounded),
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final earned = progress.totalStars(game.id);
          final maxStars = game.levelCount * 3;
          return Column(
            children: [
              _Header(game: game, earned: earned, maxStars: maxStars),
              Expanded(
                child: _mapView
                    ? JourneyMap(game: game)
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: game.levelCount,
                        itemBuilder: (context, i) => _levelTile(context, i),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _levelTile(BuildContext context, int index) {
    final progress = ProgressService.instance;
    final unlocked = progress.isUnlocked(game.id, index);
    final stars = progress.starsFor(game.id, index);

    return GestureDetector(
      onTap: unlocked ? () => startLevel(context, game, index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: unlocked ? game.color : Colors.grey.shade300,
            width: 3,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked)
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: game.color,
                ),
              )
            else
              Icon(Icons.lock_rounded, size: 34, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            if (unlocked)
              StarRow(stars: stars, size: 18)
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.game,
    required this.earned,
    required this.maxStars,
  });

  final GameInfo game;
  final int earned;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: game.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFDCB6E), size: 30),
            const SizedBox(width: 8),
            Text(
              '$earned / $maxStars',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                game.subtitle,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карта-путешествие по уровням: волнистый путь, узлы-уровни, звёзды,
/// робот на текущем уровне и замок в финале.
class JourneyMap extends StatelessWidget {
  const JourneyMap({super.key, required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final currentIndex = progress.currentLevel(game.id, game.levelCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        const perRow = 3;
        const nodeSize = 66.0;
        final rows = (game.levelCount / perRow).ceil();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              for (int r = 0; r < rows; r++)
                _mapRow(context, r, perRow, nodeSize, currentIndex),
              const SizedBox(height: 8),
              _castle(progress),
            ],
          ),
        );
      },
    );
  }

  Widget _mapRow(
    BuildContext context,
    int row,
    int perRow,
    double nodeSize,
    int currentIndex,
  ) {
    final start = row * perRow;
    final nodes = <Widget>[];
    for (int c = 0; c < perRow; c++) {
      final index = start + c;
      if (index >= game.levelCount) {
        nodes.add(const SizedBox(width: 66, height: 96));
      } else {
        nodes.add(_node(context, index, nodeSize, currentIndex));
      }
    }
    final shift = row.isEven ? 0.0 : 28.0;
    return Padding(
      padding: EdgeInsets.only(top: 10, left: shift),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: nodes,
      ),
    );
  }

  Widget _node(BuildContext context, int index, double size, int currentIndex) {
    final progress = ProgressService.instance;
    final unlocked = progress.isUnlocked(game.id, index);
    final stars = progress.starsFor(game.id, index);
    final isCurrent = index == currentIndex && unlocked && stars == 0;
    final isFinal = index == game.levelCount - 1;
    final color = unlocked ? game.color : Colors.grey.shade400;

    return GestureDetector(
      onTap: unlocked ? () => startLevel(context, game, index) : null,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            const SizedBox(height: 4),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked ? Colors.white : Colors.grey.shade200,
                    border: Border.all(color: color, width: 4),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isFinal && unlocked
                      ? const Text('🏰', style: TextStyle(fontSize: 30))
                      : unlocked
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        )
                      : Icon(
                          Icons.lock_rounded,
                          size: 26,
                          color: Colors.grey.shade500,
                        ),
                ),
                if (isCurrent)
                  Positioned(
                    top: -18,
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (unlocked)
              StarRow(stars: stars, size: 13)
            else
              const SizedBox(height: 13),
          ],
        ),
      ),
    );
  }

  Widget _castle(ProgressService progress) {
    return Column(
      children: [
        const Text('🏁', style: TextStyle(fontSize: 34)),
        Text(
          'Финиш!',
          style: TextStyle(fontWeight: FontWeight.w800, color: game.color),
        ),
      ],
    );
  }
}
