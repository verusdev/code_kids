import 'package:code_kids/screens/python/python_lesson_screen.dart';
import 'package:code_kids/widgets/turtle_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Высокий «экран», чтобы все карточки урока построились (ListView ленивый).
Future<void> _pumpLesson(WidgetTester tester, int index) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: PythonLessonScreen(lessonIndex: index)),
  );
  await tester.pumpAndSettle();
}

Future<void> _runExample(WidgetTester tester) async {
  await tester.tap(find.text('Запустить пример'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('урок 11 (input): пример печатает вопрос и ответ', (tester) async {
    await _pumpLesson(tester, 10);
    await _runExample(tester);
    expect(find.text('Как тебя зовут? '), findsWidgets);
    expect(find.text('Привет, Ника'), findsWidgets);
  });

  testWidgets('урок 12 (срезы): пример печатает части слова', (tester) async {
    await _pumpLesson(tester, 11);
    await _runExample(tester);
    expect(find.text('Програм'), findsWidgets);
    expect(find.text('ание'), findsWidgets);
  });

  testWidgets('урок 13 (словари): пример печатает значение и длину', (tester) async {
    await _pumpLesson(tester, 12);
    await _runExample(tester);
    expect(find.text('50'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('урок 14 (черепашка): пример рисует линии на холсте',
      (tester) async {
    await _pumpLesson(tester, 13);
    final before = tester.widget<TurtleCanvas>(find.byType(TurtleCanvas).first);
    expect(before.segments, isEmpty);
    await _runExample(tester);
    final after = tester.widget<TurtleCanvas>(find.byType(TurtleCanvas).first);
    expect(after.segments, isNotEmpty);
  });
}
