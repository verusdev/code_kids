import 'package:code_kids/models/python_lesson.dart';
import 'package:code_kids/python/lessons/python_course.dart';
import 'package:code_kids/python/python_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('в курсе не меньше 14 уроков и все названия уникальны', () {
    expect(pythonLessons.length, greaterThanOrEqualTo(14));
    final titles = pythonLessons.map((l) => l.title).toSet();
    expect(titles.length, pythonLessons.length);
  });

  test('у каждого урока заполнены задание, ожидаемый вывод и подсказка', () {
    for (final lesson in pythonLessons) {
      expect(lesson.task.trim(), isNotEmpty, reason: lesson.title);
      expect(lesson.expectedOutput.trim(), isNotEmpty, reason: lesson.title);
      expect(lesson.hint.trim(), isNotEmpty, reason: lesson.title);
      expect(lesson.theory, isNotEmpty, reason: lesson.title);
    }
  });

  test('пример кода каждого урока запускается без ошибок', () {
    for (final lesson in pythonLessons) {
      final result = PythonRunner.run(
        lesson.exampleCode,
        inputs: lesson.exampleInputs,
      );
      expect(result.ok, isTrue,
          reason: '${lesson.title}: ${result.error}');
    }
  });

  test('стартовый код каждого урока запускается без ошибок', () {
    for (final lesson in pythonLessons) {
      final result = PythonRunner.run(
        lesson.startCode,
        inputs: lesson.inputs,
      );
      expect(result.ok, isTrue,
          reason: '${lesson.title}: ${result.error}');
    }
  });

  test('среди уроков есть черепашка, и её пример что-то рисует', () {
    final turtleLesson = pythonLessons.firstWhere((l) => l.drawsTurtle);
    final result = PythonRunner.run(turtleLesson.exampleCode);
    expect(result.ok, isTrue, reason: '${result.error}');
    expect(result.turtleSegments, isNotEmpty);
  });

  test('normalize убирает лишние пробелы и пустые строки в конце', () {
    expect(PythonLesson.normalize('a  \nb\n\n'), 'a\nb');
    expect(PythonLesson.normalize('  x  '), 'x');
  });
}
