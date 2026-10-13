import 'package:flutter/material.dart';

import '../models/game_models.dart';

/// Карточка игры на главном экране: эмодзи, название и собранные звёзды.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.earnedStars,
    required this.onTap,
  });

  final GameInfo game;
  final int earnedStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final maxStars = game.levelCount * 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border(
                left: BorderSide(color: game.color, width: 8),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(game.emoji, style: const TextStyle(fontSize: 34)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFDCB6E), size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '$earnedStars / $maxStars',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: game.color, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
