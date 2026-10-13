import 'package:flutter/material.dart';

import '../games/game_definition.dart';
import '../models/game_models.dart';
import '../services/progress_service.dart';
import '../widgets/star_row.dart';

/// Экран выбора уровня внутри одной игры.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: Text('${game.emoji} ${game.title}')),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final earned = progress.totalStars(game.id);
          final maxStars = game.levelCount * 3;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFDCB6E), size: 30),
                      const SizedBox(width: 8),
                      Text(
                        '$earned / $maxStars',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        game.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
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
              Icon(Icons.lock_rounded,
                  size: 34, color: Colors.grey.shade400),
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
