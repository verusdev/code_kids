import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../services/achievements_service.dart';
import '../services/daily_service.dart';
import '../services/progress_service.dart';
import 'achievement_dialog.dart';
import 'daily_dialog.dart';

/// Следит за прогрессом и показывает поздравления: сначала с новыми медалями,
/// затем — с выполненным заданием дня (по одному окну, без наложений).
class RewardsWatcher extends StatefulWidget {
  const RewardsWatcher({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<RewardsWatcher> createState() => _RewardsWatcherState();
}

class _RewardsWatcherState extends State<RewardsWatcher> {
  @override
  void initState() {
    super.initState();
    ProgressService.instance.addListener(_onChange);
    DailyService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ProgressService.instance.removeListener(_onChange);
    DailyService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    // Ждём следующий кадр: к этому моменту навигатор уже готов показать окно.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final context = widget.navigatorKey.currentContext;
      if (context == null) return;

      final medals =
          AchievementsService.instance.takeNewlyUnlocked(currentSnapshot());
      if (medals.isNotEmpty) {
        await showAchievementsDialog(context, medals);
        if (!context.mounted) return;
      }

      final quest = DailyService.instance.takeNewlyCompletedQuest();
      if (quest != null) {
        await showDailyQuestDialog(context, quest);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
