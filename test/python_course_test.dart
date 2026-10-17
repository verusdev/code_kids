import 'package:code_kids/models/python_lesson.dart';
import 'package:code_kids/python/lessons/python_course.dart';
import 'package:code_kids/python/python_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Полные решения заданий уроков 21–30 (индексы 20–29 в [pythonLessons]).
///
/// Ключ — индекс урока (с нуля), значение — готовый код, который должен
/// привести к `lesson.expectedOutput` при подстановке `lesson.inputs`.
const Map<int, String> _solutions = {
  // 21. Модуль random.
  20: "import random\n"
      "животные = ['тигр', 'слон', 'гусь', 'лось']\n"
      "print(len(random.choice(животные)))\n",
  // 22. Замена и подсчёт.
  21: "фраза = 'Пррривет'\n"
      "исправленная = фраза.replace('ррр', 'р')\n"
      "print(исправленная)\n"
      "print(исправленная.count('р'))\n",
  // 23. Сортировка списка.
  22: "оценки = [4, 5, 3, 5]\n"
      "отсортированные = sorted(оценки)\n"
      "print(отсортированные[-1])\n"
      "print(отсортированные[0])\n",
  // 24. Программа не падает (try / except).
  23: "делители = [4, 0, 5]\n"
      "for d in делители:\n"
      "    try:\n"
      "        print(100 / d)\n"
      "    except ZeroDivisionError:\n"
      "        print('Нельзя делить на ноль')\n",
  // 25. Проект: мини-квиз.
  24: "вопросы = {'2 + 2 = ?': '4', '3 + 3 = ?': '6', '10 - 4 = ?': '6'}\n"
      "счёт = 0\n"
      "for вопрос in вопросы:\n"
      "    ответ = input(вопрос + ' ')\n"
      "    if ответ == вопросы[вопрос]:\n"
      "        счёт = счёт + 1\n"
      "print('Правильных:', счёт)\n",
  // 26. Проект: угадай число.
  25: "загаданное = 7\n"
      "попыток = 0\n"
      "while True:\n"
      "    ч = int(input('Твоё число: '))\n"
      "    попыток = попыток + 1\n"
      "    if ч == загаданное:\n"
      "        print('Угадал! Попыток:', попыток)\n"
      "        break\n"
      "    elif ч < загаданное:\n"
      "        print('Больше!')\n"
      "    else:\n"
      "        print('Меньше!')\n",
  // 27. Разбираем фразу на слова (split).
  26: "фраза = 'Я люблю кодить'\n"
      "слова = фраза.split()\n"
      "for слово in слова:\n"
      "    print(слово, len(слово))\n",
  // 28. Черепашка: узор в узоре.
  27: "for i in range(8):\n"
      "    for j in range(4):\n"
      "        turtle.forward(40)\n"
      "        turtle.right(90)\n"
      "    turtle.right(45)\n"
      "print('Готово!')\n",
  // 29. Камень-ножницы-бумага.
  28: "победы = 0\n\n"
      "def победил(игрок, соперник):\n"
      "    if игрок == соперник:\n"
      "        return False\n"
      "    if (игрок == 'камень' and соперник == 'ножницы') or "
      "(игрок == 'ножницы' and соперник == 'бумага') or "
      "(игрок == 'бумага' and соперник == 'камень'):\n"
      "        return True\n"
      "    return False\n\n"
      "for раунд in range(1, 4):\n"
      "    игрок = input('Твой ход: ')\n"
      "    соперник = input('Ход соперника: ')\n"
      "    if победил(игрок, соперник):\n"
      "        победы = победы + 1\n"
      "        print('Раунд', раунд, '— Победа!')\n"
      "    elif игрок == соперник:\n"
      "        print('Раунд', раунд, '— Ничья')\n"
      "    else:\n"
      "        print('Раунд', раунд, '— Мимо')\n"
      "print('Побед:', победы)\n",
  // 30. Итог: черепашкий городок.
  29: "def домик(длина):\n"
      "    for i in range(4):\n"
      "        turtle.forward(длина)\n"
      "        turtle.right(90)\n\n"
      "for улица in range(2):\n"
      "    домик(60)\n"
      "    turtle.penup()\n"
      "    turtle.forward(120)\n"
      "    turtle.pendown()\n"
      "print('Готово!')\n",
};

void main() {
  test('в курсе не меньше 30 уроков и все названия уникальны', () {
    expect(pythonLessons.length, greaterThanOrEqualTo(30));
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

  test('решения заданий уроков 21–30 дают ожидаемый вывод', () {
    expect(pythonLessons.length, greaterThanOrEqualTo(30));
    for (final entry in _solutions.entries) {
      final lesson = pythonLessons[entry.key];
      final result = PythonRunner.run(entry.value, inputs: lesson.inputs);
      expect(result.ok, isTrue,
          reason: '${lesson.title}: ${result.error}');
      expect(lesson.matches(result.outputText), isTrue,
          reason: '${lesson.title}:\n'
              '--- получено ---\n${result.outputText}\n'
              '--- ожидалось ---\n${lesson.expectedOutput}');
    }
  });
}
