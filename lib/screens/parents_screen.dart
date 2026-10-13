import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../models/game_models.dart';
import '../python/lessons/python_course.dart';
import '../services/daily_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Экран «Родителям»: общая картина успехов ребёнка и советы.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('👨‍👩‍👧 Родителям')),
      body: ListenableBuilder(
        listenable:
            Listenable.merge([progress, DailyService.instance]),
        builder: (context, _) {
          final all = [...kGames, ...kSystemGames, kPythonCourse];

          var earned = 0;
          var maxStars = 0;
          var passed = 0;
          var levels = 0;
          for (final game in all) {
            earned += progress.totalStars(game.id);
            maxStars += game.levelCount * 3;
            levels += game.levelCount;
            for (var i = 0; i < game.levelCount; i++) {
              if (progress.starsFor(game.id, i) > 0) passed++;
            }
          }

          final snapshot = currentSnapshot();
          final medals =
              kAchievements.where((a) => a.isUnlocked(snapshot)).length;
          final daily = DailyService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SummaryCard(
                earned: earned,
                maxStars: maxStars,
                passed: passed,
                levels: levels,
                medals: medals,
                streak: daily.streak,
                bestStreak: daily.bestStreak,
              ),
              const SizedBox(height: 16),
              _SectionTitle('📊 Прогресс по разделам'),
              for (final game in all)
                _GameProgressRow(
                  game: game,
                  stars: progress.totalStars(game.id),
                  passedLevels: List.generate(game.levelCount,
                          (i) => progress.starsFor(game.id, i))
                      .where((v) => v > 0)
                      .length,
                ),
              const SizedBox(height: 16),
              _SectionTitle('💡 Как помочь ребёнку'),
              const _AdviceCard(),
              const SizedBox(height: 16),
              _SectionTitle('🔧 Настройки'),
              _ResetTile(progress: progress),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.earned,
    required this.maxStars,
    required this.passed,
    required this.levels,
    required this.medals,
    required this.streak,
    required this.bestStreak,
  });

  final int earned;
  final int maxStars;
  final int passed;
  final int levels;
  final int medals;
  final int streak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.purple, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Успехи ребёнка',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Stat('⭐', 'Звёзды', '$earned из $maxStars'),
              _Stat('🏁', 'Уровни', '$passed из $levels'),
              _Stat('🏅', 'Медали', '$medals из ${kAchievements.length}'),
              _Stat('🔥', 'Серия', '$streak дн.'),
              _Stat('🏆', 'Рекорд', '$bestStreak дн.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.label, this.value);

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $label',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameProgressRow extends StatelessWidget {
  const _GameProgressRow({
    required this.game,
    required this.stars,
    required this.passedLevels,
  });

  final GameInfo game;
  final int stars;
  final int passedLevels;

  @override
  Widget build(BuildContext context) {
    final maxStars = game.levelCount * 3;
    final value = maxStars == 0 ? 0.0 : (stars / maxStars).clamp(0.0, 1.0);
    final color = AppTheme.gameColors[game.id] ?? AppTheme.purple;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$stars / $maxStars ⭐',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Пройдено уровней: $passedLevels из ${game.levelCount}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('⏱️', 'Занимайтесь по 10–15 минут в день — коротко и регулярно.'),
      ('🤝', 'Если не получается — не спешите подсказывать, дайте подумать.'),
      ('🗣️', 'Просите ребёнка объяснить, что делает его программа.'),
      ('🎉', 'Хвалите за старание, а не только за звёзды.'),
      ('🔁', 'Повторять пройденные уровни полезно — это закрепление.'),
      ('💬', 'Ошибки в коде — нормально: это повод посмотреть консоль вместе.'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip.$2,
                      style: const TextStyle(fontSize: 14, height: 1.35),
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

class _ResetTile extends StatelessWidget {
  const _ResetTile({required this.progress});

  final ProgressService progress;

  Future<void> _confirmReset(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить весь прогресс?'),
        content: const Text(
          'Звёзды, медали и серия будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await progress.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прогресс сброшен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Сбросить прогресс'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.pink,
          side: const BorderSide(color: AppTheme.pink, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
