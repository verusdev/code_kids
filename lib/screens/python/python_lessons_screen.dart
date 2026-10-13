import 'package:flutter/material.dart';

import '../../python/lessons/python_course.dart';
import '../../services/progress_service.dart';
import '../../widgets/star_row.dart';
import 'python_lesson_screen.dart';

/// Экран со списком уроков Python-курса.
class PythonLessonsScreen extends StatelessWidget {
  const PythonLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('🐍 Python-курс')),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final earned = progress.totalStars('python');
          final maxStars = pythonLessons.length * 3;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _IntroCard(earned: earned, maxStars: maxStars),
              const SizedBox(height: 14),
              for (int i = 0; i < pythonLessons.length; i++)
                _LessonTile(index: i),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.earned, required this.maxStars});

  final int earned;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3776AB), Color(0xFF5A9BD4)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐍', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Учись писать код на Python!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'От первой команды print() до своих функций. '
            'Читай объяснение, запускай пример и решай задания.',
            style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFDCB6E), size: 24),
                const SizedBox(width: 6),
                Text(
                  '$earned / $maxStars',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final lesson = pythonLessons[index];
    final unlocked = progress.isUnlocked('python', index);
    final stars = progress.starsFor('python', index);
    const color = Color(0xFF3776AB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unlocked ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(22),
        elevation: unlocked ? 3 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PythonLessonScreen(lessonIndex: index),
                    ),
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border(
                left: BorderSide(
                  color: unlocked ? color : Colors.grey.shade400,
                  width: 7,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? color.withValues(alpha: 0.14)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: unlocked
                      ? Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        )
                      : Icon(Icons.lock_rounded,
                          size: 22, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: unlocked ? null : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.goal,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (unlocked) ...[
                        const SizedBox(height: 8),
                        StarRow(stars: stars, size: 18),
                      ],
                    ],
                  ),
                ),
                Icon(
                  unlocked
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: unlocked ? color : Colors.grey.shade400,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
