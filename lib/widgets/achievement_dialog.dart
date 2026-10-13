import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/app_theme.dart';

/// Показывает поздравление с новыми медалями (одно окно на все сразу).
Future<void> showAchievementsDialog(
  BuildContext context,
  List<Achievement> fresh,
) {
  if (fresh.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (context) => _AchievementsDialog(fresh: fresh),
  );
}

class _AchievementsDialog extends StatelessWidget {
  const _AchievementsDialog({required this.fresh});

  final List<Achievement> fresh;

  @override
  Widget build(BuildContext context) {
    final many = fresh.length > 1;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 6),
            Text(
              many ? 'Новые медали!' : 'Новая медаль!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in fresh) _MedalRow(achievement: a),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ура! 🎉'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.yellow.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
