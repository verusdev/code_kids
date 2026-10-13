import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../models/game_models.dart';
import '../python/lessons/python_course.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_card.dart';
import '../widgets/game_card.dart';
import '../widgets/parent_gate.dart';
import 'achievements_screen.dart';
import 'challenge_screen.dart';
import 'how_to_play_screen.dart';
import 'level_select_screen.dart';
import 'parents_screen.dart';
import 'settings_screen.dart';
import 'python/python_lessons_screen.dart';

/// Главный экран: приветствие и список мини-игр с прогрессом.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: progress,
          builder: (context, _) {
            final total = [...kGames, ...kSystemGames].fold<int>(
                  0,
                  (sum, g) => sum + progress.totalStars(g.id),
                ) +
                progress.totalStars('python');

            final achieved =
                kAchievements.where((a) => a.isUnlocked(currentSnapshot())).length;

            Widget card(GameInfo game, VoidCallback onTap) => GameCard(
                  game: game,
                  earnedStars: progress.totalStars(game.id),
                  onTap: onTap,
                );

            Widget sectionTitle(String title) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 2),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );

            VoidCallback openGame(GameInfo game) => () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => LevelSelectScreen(game: game)));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context, total)),
                const SliverToBoxAdapter(child: DailyCard()),
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (final game in kGames) card(game, openGame(game)),
                    sectionTitle('🧩 Системное мышление'),
                    for (final game in kSystemGames)
                      card(game, openGame(game)),
                    sectionTitle('🐍 Программирование на Python'),
                    card(
                      kPythonCourse,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PythonLessonsScreen(),
                        ),
                      ),
                    ),
                  ]),
                ),
                SliverToBoxAdapter(child: _footer(context, achieved)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int totalStars) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.purple, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Код-Квест',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Учимся программировать и думать!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFDCB6E), size: 26),
                const SizedBox(width: 6),
                Text(
                  'Собрано звёзд: $totalStars',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, int achieved) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: [
          const SizedBox(
            height: 6,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ),
              icon: const Icon(Icons.emoji_events_rounded),
              label: Text('Достижения ($achieved/${kAchievements.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChallengeScreen()),
              ),
              icon: const Icon(Icons.sports_score_rounded),
              label: const Text('🏆 Испытание'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
              ),
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Как играть?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.purple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final passed = await showParentGate(context);
                  if (!passed) return;
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const ParentsScreen()),
                  );
                },
                icon: const Icon(Icons.family_restroom_rounded),
                label: const Text('Родителям'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Настройки'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
