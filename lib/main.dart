import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/achievements_service.dart';
import 'services/challenge_service.dart';
import 'services/daily_service.dart';
import 'services/playtime_service.dart';
import 'services/profile_service.dart';
import 'services/progress_service.dart';
import 'services/settings_service.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
import 'widgets/rewards_watcher.dart';

/// Ключ навигатора: нужен, чтобы показывать окна с наградами
/// из любого места приложения.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Сначала загружаем профили: остальные сервисы читают данные
  // текущего профиля (ключи вида `<base>::<profileId>`).
  await ProfileService.instance.load();
  // Загружаем сохранённые данные до первого кадра.
  await ProgressService.instance.load();
  await AchievementsService.instance.load();
  await DailyService.instance.load();
  await SettingsService.instance.load();
  await ChallengeService.instance.load();
  await PlaytimeService.instance.load();
  await SpeechService.instance.init();
  // Начинаем считать время, проведённое в приложении.
  PlaytimeService.instance.startSession();
  runApp(const CodeKidsApp());
}

/// «Код-Квест» — приложение для обучения второклассников программированию
/// и логике в формате мини-игр с уровнями.
class CodeKidsApp extends StatelessWidget {
  const CodeKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Код-Квест',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light(),
      home: RewardsWatcher(
        navigatorKey: rootNavigatorKey,
        child: const HomeScreen(),
      ),
    );
  }
}
