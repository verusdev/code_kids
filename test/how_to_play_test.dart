// Проверка экрана «Как играть?»: заголовок, приветствие и карточка-подсказка
// для каждой игры (в том числе про баг, секретный код и Python-курс).
import 'package:code_kids/models/game_models.dart';
import 'package:code_kids/python/lessons/python_course.dart';
import 'package:code_kids/screens/how_to_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Высокий «экран», чтобы ленивый ListView построил все карточки.
Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('показывает заголовок и приветствие кота Байта', (tester) async {
    await _pump(tester);
    expect(find.text('Как играть?'), findsOneWidget);
    expect(find.textContaining('кот Байт'), findsOneWidget);
  });

  testWidgets('у каждой игры и у Python-курса есть карточка', (tester) async {
    await _pump(tester);
    final games = <GameInfo>[...kGames, ...kSystemGames, kPythonCourse];
    expect(games.length, greaterThanOrEqualTo(13));
    for (final g in games) {
      expect(find.text(g.title), findsOneWidget,
          reason: 'нет карточки для игры «${g.title}»');
    }
  });

  testWidgets('подсказки про баг, код и Python на месте', (tester) async {
    await _pump(tester);
    // Подсказка для «Поймай багу».
    expect(find.textContaining('есть ошибка'), findsOneWidget);
    // Подсказка для «Секретного кода».
    expect(find.textContaining('двоичный код'), findsOneWidget);
    // Подсказка для Python-курса.
    expect(find.textContaining('настоящий код'), findsOneWidget);
  });

  testWidgets('подсказки для остальных игр тоже отрисованы', (tester) async {
    await _pump(tester);
    expect(find.textContaining('Вперёд'), findsWidgets);
    expect(find.textContaining('Повторить N раз'), findsOneWidget);
    expect(find.textContaining('Призрачные клетки'), findsOneWidget);
    expect(find.textContaining('шифр Цезаря'), findsOneWidget);
    expect(find.textContaining('пропавшую часть'), findsOneWidget);
  });

  testWidgets('внизу есть подсказка про звёзды', (tester) async {
    await _pump(tester);
    expect(find.textContaining('Чем меньше ошибок'), findsOneWidget);
  });
}
