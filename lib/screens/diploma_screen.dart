import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../models/game_models.dart';
import '../python/lessons/python_course.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/print_helper.dart';
import '../widgets/kid_button.dart';

/// Экран «Диплом» — именная грамота по итогам обучения.
///
/// Показывает имя ребёнка, собранные звёзды, пройденные уровни и медали.
/// На веб-платформе есть кнопка «Распечатать» (диалог печати браузера).
class DiplomaScreen extends StatelessWidget {
  const DiplomaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final profile = ProfileService.instance.current;
    final all = [...kGames, ...kSystemGames, kPythonCourse];

    var earned = 0;
    var passed = 0;
    var levels = 0;
    for (final game in all) {
      earned += progress.totalStars(game.id);
      levels += game.levelCount;
      for (var i = 0; i < game.levelCount; i++) {
        if (progress.starsFor(game.id, i) > 0) passed++;
      }
    }
    final medals = kAchievements
        .where((a) => a.isUnlocked(currentSnapshot()))
        .length;

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final date = '${two(now.day)}.${two(now.month)}.${now.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('📜 Диплом')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFDCB6E), width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 4),
                const Text(
                  'ДИПЛОМ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.purple,
                  ),
                ),
                const Text(
                  '«Код-Квест» — школа программирования',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Награждается',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  '${profile.emoji} ${profile.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'за успехи в изучении программирования и логики',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Badge('⭐', '$earned звёзд'),
                    _Badge('🏁', '$passed из $levels'),
                    _Badge('🏅', '$medals медалей'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Выдан $date',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (webPrintAvailable())
            KidButton(
              label: 'Распечатать диплом',
              emoji: '🖨️',
              onPressed: printPage,
            )
          else
            const Text(
              'Чтобы сохранить диплом, сделай снимок экрана 🙂',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.emoji, this.label);

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
