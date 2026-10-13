import 'package:flutter/material.dart';

import '../services/daily_service.dart';
import '../theme/app_theme.dart';

/// Карточка на главном экране: серия дней и задание дня с прогрессом.
class DailyCard extends StatelessWidget {
  const DailyCard({super.key});

  /// Правильная форма слова «день» для числа [n].
  static String daysWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'дня';
    return 'дней';
  }

  @override
  Widget build(BuildContext context) {
    final daily = DailyService.instance;
    return ListenableBuilder(
      listenable: daily,
      builder: (context, _) {
        final quest = daily.quest;
        final progress = daily.questProgress.clamp(0, quest.target);
        final done = daily.questDone;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.yellow, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Серия: ${daily.streak} ${daysWord(daily.streak)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  if (daily.bestStreak > daily.streak)
                    Text(
                      'рекорд ${daily.bestStreak}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                daily.playedToday
                    ? 'Сегодня уже играл — так держать!'
                    : 'Поиграй сегодня, чтобы серия не прервалась',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Text(quest.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Задание дня: ${quest.title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: quest.target == 0 ? 0 : progress / quest.target,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFEDEFF3),
                  valueColor: AlwaysStoppedAnimation(
                    done ? AppTheme.teal : AppTheme.orange,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                done ? 'Выполнено! 🎉' : '$progress из ${quest.target}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: done ? AppTheme.teal : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
