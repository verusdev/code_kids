import 'package:code_kids/games/game_common.dart';
import 'package:code_kids/models/game_models.dart';
import 'package:code_kids/screens/challenge_screen.dart';
import 'package:code_kids/services/challenge_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ChallengeSession.reset();
    await ChallengeService.instance.reset();
  });

  tearDown(() => ChallengeSession.reset());

  group('ChallengeService', () {
    test('хранит только лучший результат и загружается обратно', () async {
      expect(ChallengeService.instance.hasRecord, isFalse);

      expect(await ChallengeService.instance.record(40), isTrue);
      expect(ChallengeService.instance.bestSeconds, 40);

      expect(await ChallengeService.instance.record(55), isFalse);
      expect(ChallengeService.instance.bestSeconds, 40);

      expect(await ChallengeService.instance.record(30), isTrue);
      expect(ChallengeService.instance.bestSeconds, 30);

      await ChallengeService.instance.load();
      expect(ChallengeService.instance.bestSeconds, 30);
    });

    test('formatDuration выводит красивое время', () {
      expect(formatDuration(5), '0:05');
      expect(formatDuration(65), '1:05');
      expect(formatDuration(600), '10:00');
    });
  });

  group('ChallengeSession', () {
    test('старт, стоп и сброс', () {
      ChallengeSession.start(10);
      expect(ChallengeSession.active, isTrue);
      expect(ChallengeSession.total, 10);
      expect(ChallengeSession.current, 0);

      ChallengeSession.current = 3;
      ChallengeSession.seconds.value = 12;
      expect(ChallengeSession.seconds.value, 12);

      ChallengeSession.stop();
      expect(ChallengeSession.active, isFalse);
      expect(ChallengeSession.seconds.value, 12);
    });
  });

  group('экраны приложения подстраиваются под испытание', () {
    testWidgets('подсказка скрыта во время испытания', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HintBar(text: 'Секрет решенья'))),
      );
      expect(find.text('Секрет решенья'), findsOneWidget);

      ChallengeSession.start(5);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HintBar(text: 'Другой секрет'))),
      );
      await tester.pump();
      expect(find.text('Другой секрет'), findsNothing);
    });

    testWidgets('окно победы показывает «Дальше» вместо «К уровням»',
        (tester) async {
      ChallengeSession.start(10);
      ChallengeSession.current = 4;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WinOverlay(
                  game: kGames.first,
                  stars: 3,
                  maxLevelIndex: 5,
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Дальше'), findsOneWidget);
      expect(find.text('К уровням'), findsNothing);
      expect(find.text('Домой'), findsNothing);
    });

    testWidgets('на последнем задании кнопка называется «Завершить»',
        (tester) async {
      ChallengeSession.start(10);
      ChallengeSession.current = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WinOverlay(
                  game: kGames.first,
                  stars: 3,
                  maxLevelIndex: 5,
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Завершить'), findsOneWidget);
    });
  });

  group('экран «Испытание»', () {
    testWidgets('показывает описание, число заданий и кнопку старта',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChallengeScreen()));
      await tester.pump();

      expect(find.text('Начать испытание'), findsOneWidget);
      expect(find.text('Заданий: ${ChallengeScreen.tasks.length}'),
          findsOneWidget);
      expect(find.textContaining('Рекорда пока нет'), findsOneWidget);
    });

    testWidgets('испытание включает самый трудный уровень каждой игры',
        (tester) async {
      final tasks = ChallengeScreen.tasks;
      // В испытание входит ровно по одной (самой сложной) игре из реестра.
      expect(tasks.length, kGames.length + kSystemGames.length);
      expect(
        tasks.map((g) => g.id).toList(),
        [...kGames, ...kSystemGames].map((g) => g.id).toList(),
      );
      for (final game in tasks) {
        // Номер «самого трудного» уровня — levelCount - 1 (последний),
        // поэтому он должен существовать у любой игры.
        final real = gameById(game.id);
        expect(game.levelCount, real.levelCount);
        expect(game.levelCount - 1, greaterThanOrEqualTo(0));
      }
    });
  });
}
