import 'package:code_kids/screens/parents_screen.dart';
import 'package:code_kids/services/achievements_service.dart';
import 'package:code_kids/services/daily_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:code_kids/widgets/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.reset();
    await AchievementsService.instance.reset();
    await DailyService.instance.reset();
  });

  group('экран «Родителям»', () {
    testWidgets('показывает сводку и разделы', (tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ProgressService.instance.record('maze', 0, 3, 10);
      await tester.pumpWidget(const MaterialApp(home: ParentsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('👨‍👩‍👧 Родителям'), findsOneWidget);
      expect(find.text('Успехи ребёнка'), findsOneWidget);
      expect(find.text('📊 Прогресс по разделам'), findsOneWidget);
      expect(find.text('💡 Как помочь ребёнку'), findsOneWidget);
      expect(find.text('🔧 Настройки'), findsOneWidget);

      // Звёзды: 3 из (10 игр по 45 + 20*3) = 3 из 510.
      expect(find.text('3 из 510'), findsOneWidget);
      expect(find.text('1 из 170'), findsOneWidget); // уровней пройдено

      // Строка «Робот-Лабиринт» с прогрессом 3/45.
      expect(find.text('Робот-Лабиринт'), findsOneWidget);
      expect(find.text('3 / 45 ⭐'), findsWidgets);
    });

    testWidgets('сброс прогресса по кнопке очищает звёзды', (tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ProgressService.instance.record('maze', 0, 3, 10);
      await tester.pumpWidget(const MaterialApp(home: ParentsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сбросить прогресс'));
      await tester.pumpAndSettle();
      expect(find.text('Сбросить весь прогресс?'), findsOneWidget);

      await tester.tap(find.text('Сбросить'));
      await tester.pumpAndSettle();

      expect(ProgressService.instance.totalStars('maze'), 0);
      expect(find.text('0 из 510'), findsOneWidget);
    });
  });

  group('родительский замок', () {
    testWidgets('пускает при верном ответе', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final ok = await showParentGate(context);
                  if (ok) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('ВХОД РАЗРЕШЁН')));
                  }
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      // Читаем пример «a + b = ?» и нажимаем верный вариант.
      final question = tester
          .widgetList<Text>(find.textContaining('= ?'))
          .map((t) => t.data)
          .firstWhere((d) => d != null)!;
      final parts = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(question)!;
      final answer = int.parse(parts.group(1)!) + int.parse(parts.group(2)!);

      await tester.tap(find.text('$answer'));
      await tester.pumpAndSettle();

      expect(find.text('ВХОД РАЗРЕШЁН'), findsOneWidget);
    });

    testWidgets('не пускает при неверном ответе', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final ok = await showParentGate(context);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ВХОД РАЗРЕШЁН')),
                    );
                  }
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      final question = tester
          .widgetList<Text>(find.textContaining('= ?'))
          .map((t) => t.data)
          .firstWhere((d) => d != null)!;
      final parts = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(question)!;
      final answer = int.parse(parts.group(1)!) + int.parse(parts.group(2)!);

      // Берём вариант, который точно не является верным ответом.
      final options = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((d) => RegExp(r'^\d+$').hasMatch(d))
          .toList();
      final wrong = options.firstWhere((d) => d != '$answer');

      await tester.tap(find.text(wrong));
      await tester.pumpAndSettle();

      // Диалог остался, доступ не выдан.
      expect(find.text('Попробуйте ещё раз 🙂'), findsOneWidget);
      expect(find.text('ВХОД РАЗРЕШЁН'), findsNothing);
    });
  });
}
