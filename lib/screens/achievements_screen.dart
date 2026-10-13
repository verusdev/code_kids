import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../models/achievement.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Экран «Достижения»: все медали, открытые — цветные, закрытые — серые.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('🏅 Достижения')),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final snapshot = currentSnapshot();
          final unlocked =
              kAchievements.where((a) => a.isUnlocked(snapshot)).length;
          final total = kAchievements.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(unlocked: unlocked, total: total),
              const SizedBox(height: 14),
              for (final a in kAchievements)
                _AchievementTile(
                  achievement: a,
                  unlocked: a.isUnlocked(snapshot),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final done = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.orange, AppTheme.yellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Открыто медалей: $unlocked из $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: done,
              minHeight: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFFFFF)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Играй, решай задания и собирай звёзды — за это дают медали!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked ? AppTheme.yellow : const Color(0xFFDADFE6),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.yellow.withValues(alpha: 0.35)
                  : const Color(0xFFEDEFF3),
              shape: BoxShape.circle,
            ),
            child: Text(
              unlocked ? achievement.emoji : '🔒',
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: unlocked
                              ? AppTheme.ink
                              : const Color(0xFF9AA3B2),
                        ),
                      ),
                    ),
                    if (unlocked)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.teal, size: 24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? Colors.grey.shade700
                        : const Color(0xFF9AA3B2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
