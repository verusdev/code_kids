import 'package:flutter/material.dart';

import '../services/daily_service.dart';
import '../theme/app_theme.dart';

/// Поздравление с выполненным заданием дня.
Future<void> showDailyQuestDialog(BuildContext context, DailyQuest quest) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 6),
            const Text(
              'Задание дня выполнено!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.yellow.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${quest.emoji}  ${quest.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Заходи завтра за новым заданием — серия растёт!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Здорово! 👍'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
