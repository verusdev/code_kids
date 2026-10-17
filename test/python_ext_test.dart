// Расширенные проверки Python-интерпретатора: модуль random, строковые
// методы (replace / count / split / join), sorted и try / except, а также
// понятные русские тексты ошибок.
import 'package:code_kids/python/python_runner.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> run(String code) {
  final r = PythonRunner.run(code);
  if (!r.ok) fail('Неожиданная ошибка: ${r.error}');
  return r.output;
}

/// Проверяет, что код падает, и возвращает текст ошибки.
String errorMessage(String code) {
  final r = PythonRunner.run(code);
  expect(r.ok, isFalse, reason: 'ожидали ошибку, но код выполнился:\n$code');
  return r.error!.message;
}

void main() {
  group('import random', () {
    test('randint остаётся в границах (много бросков)', () {
      final out = run('''
import random
ок = 0
for i in range(50):
    x = random.randint(3, 6)
    if x >= 3 and x <= 6:
        ок = ок + 1
print(ок)
''');
      expect(out, ['50']);
    });

    test('randint(a, a) всегда даёт a', () {
      expect(run("import random\nprint(random.randint(7, 7))"), ['7']);
    });

    test('randint: первое число не должно быть больше второго', () {
      expect(
        errorMessage('import random\nprint(random.randint(5, 1))'),
        contains('не может быть больше'),
      );
    });

    test('randint требует два аргумента', () {
      expect(
        errorMessage('import random\nprint(random.randint(1))'),
        contains('принимает два числа'),
      );
    });

    test('randint требует целые числа', () {
      expect(
        errorMessage("import random\nprint(random.randint('a', 2))"),
        contains('ждёт целые числа'),
      );
    });

    test('choice выбирает элемент списка', () {
      expect(
        run("import random\nprint(random.choice(['только']))"),
        ['только'],
      );
    });

    test('choice ждёт список', () {
      expect(
        errorMessage('import random\nprint(random.choice(5))'),
        contains('ждёт список'),
      );
    });

    test('choice пустого списка — ошибка', () {
      expect(
        errorMessage('import random\nprint(random.choice([]))'),
        contains('список пуст'),
      );
    });

    test('choice принимает ровно один список', () {
      expect(
        errorMessage('import random\nprint(random.choice([1], 2))'),
        contains('принимает один список'),
      );
    });

    test('random.random() возвращает дробь от 0 до 1', () {
      expect(
        run('import random\nr = random.random()\nprint(r >= 0.0 and r < 1.0)'),
        ['True'],
      );
    });

    test('просто random() — то же самое, что random.random()', () {
      expect(run('import random\nprint(random() >= 0.0)'), ['True']);
    });

    test('random.random() не принимает аргументов', () {
      expect(
        errorMessage('import random\nprint(random.random(1))'),
        contains('не принимает значений'),
      );
    });

    test('поддерживается только import random', () {
      expect(errorMessage('import math'), contains('только import random'));
    });

    test('у random нет неизвестной функции', () {
      expect(
        errorMessage('import random\nrandom.неизвестно()'),
        contains('У random нет функции'),
      );
    });
  });

  group('строки: replace и count', () {
    test('replace меняет все вхождения', () {
      expect(
        run("print('Привет, мир!'.replace('мир', 'кот'))"),
        ['Привет, кот!'],
      );
    });

    test('replace не меняет исходную строку', () {
      expect(
        run("текст = 'мир мир'\nтекст.replace('мир', 'кот')\nprint(текст)"),
        ['мир мир'],
      );
    });

    test('replace принимает два кусочка текста', () {
      expect(
        errorMessage("print('a'.replace('a', 'b', 1))"),
        contains('принимает два кусочка'),
      );
      expect(
        errorMessage("print('a'.replace(1, 'b'))"),
        contains('принимает два кусочка'),
      );
    });

    test('replace не может искать пустой кусочек', () {
      expect(
        errorMessage("print('a'.replace('', 'b'))"),
        contains('пустой кусочек'),
      );
    });

    test('count считает вхождения без нахлёста', () {
      expect(run("print('ааа'.count('а'))"), ['3']);
      expect(run("print('ааа'.count('аа'))"), ['1']);
    });

    test('count принимает один кусочек текста', () {
      expect(errorMessage("print('a'.count())"),
          contains('принимает один кусочек'));
      expect(errorMessage("print('a'.count(1))"),
          contains('принимает один кусочек'));
    });
  });

  group('строки: split и join', () {
    test('split() без аргумента режет по пробелам', () {
      expect(
        run("print('мама мыла  раму'.split())"),
        ["['мама', 'мыла', 'раму']"],
      );
    });

    test('split(разделитель) режет по разделителю', () {
      expect(run("print('а,б,в'.split(','))"), ["['а', 'б', 'в']"]);
    });

    test('split принимает не больше одного разделителя', () {
      expect(
        errorMessage("print('a'.split(',', 1))"),
        contains('не больше одного разделителя'),
      );
    });

    test('разделитель split не может быть пустым', () {
      expect(
        errorMessage("print('a'.split(''))"),
        contains('Разделитель не может быть пустым'),
      );
    });

    test('split() ждёт текст-разделитель', () {
      expect(
        errorMessage("print('a'.split(1))"),
        contains('ждёт текст-разделитель'),
      );
    });

    test('join склеивает список строк', () {
      expect(
        run("print('-'.join(['а', 'б', 'в']))"),
        ['а-б-в'],
      );
    });

    test('join принимает список строк', () {
      expect(
        errorMessage("print('a'.join('б'))"),
        contains('принимает список строк'),
      );
    });

    test('join склеивает только строки', () {
      expect(
        errorMessage("print('a'.join([1, 2]))"),
        contains('склеивает только строки'),
      );
    });
  });

  group('sorted', () {
    test('сортирует числа по возрастанию', () {
      expect(run('print(sorted([3, 1, 4, 1, 5]))'), ['[1, 1, 3, 4, 5]']);
    });

    test('сортирует строки', () {
      expect(run("print(sorted(['б', 'а', 'в']))"), ["['а', 'б', 'в']"]);
    });

    test('не меняет исходный список', () {
      expect(
        run('числа = [3, 1, 2]\nprint(sorted(числа))\nprint(числа)'),
        ['[1, 2, 3]', '[3, 1, 2]'],
      );
    });

    test('смешанный список даёт понятную ошибку', () {
      expect(
        errorMessage("print(sorted([1, 'а']))"),
        contains('только числа или только строки'),
      );
    });

    test('sorted принимает список', () {
      expect(errorMessage('print(sorted(5))'), contains('принимает список'));
    });
  });

  group('try / except', () {
    test('голый except ловит любую ошибку', () {
      expect(
        run('try:\n    print(5 / 0)\nexcept:\n    print(\'поймали\')'),
        ['поймали'],
      );
    });

    test('except ZeroDivisionError ловит деление на ноль', () {
      expect(
        run('try:\n'
            '    print(10 / 0)\n'
            'except ZeroDivisionError:\n'
            "    print('нельзя')"),
        ['нельзя'],
      );
    });

    test('except NameError ловит неизвестное имя', () {
      expect(
        run('try:\n'
            '    print(неизвестно)\n'
            'except NameError:\n'
            "    print('нет имени')"),
        ['нет имени'],
      );
    });

    test('except ValueError ловит плохое преобразование в int', () {
      expect(
        run('try:\n'
            "    x = int('abc')\n"
            'except ValueError:\n'
            "    print('плохое число')"),
        ['плохое число'],
      );
    });

    test('except TypeError ловит несовместимые типы', () {
      expect(
        run('try:\n'
            "    print(sorted([1, 'а']))\n"
            'except TypeError:\n'
            "    print('типы')"),
        ['типы'],
      );
    });

    test('неподходящий тип ошибки не перехватывается', () {
      expect(
        errorMessage('try:\n'
            '    print(5 / 0)\n'
            'except ValueError:\n'
            "    print('нет')"),
        contains('Деление на ноль'),
      );
    });

    test('лимиты безопасности не перехватываются через except', () {
      expect(
        errorMessage('try:\n'
            '    while True:\n'
            '        pass\n'
            'except:\n'
            "    print('нет')"),
        contains('долго'),
      );
    });

    test('после except программа продолжает работу', () {
      expect(
        run('try:\n'
            '    print(5 / 0)\n'
            'except:\n'
            "    print('ой')\n"
            "print('дальше')"),
        ['ой', 'дальше'],
      );
    });

    test('пример урока 24: деление продолжается после ловушки', () {
      expect(
        run('делители = [4, 0, 5]\n'
            'for d in делители:\n'
            '    try:\n'
            '        print(100 / d)\n'
            '    except ZeroDivisionError:\n'
            "        print('Нельзя делить на ноль')"),
        ['25.0', 'Нельзя делить на ноль', '20.0'],
      );
    });
  });

  group('понятные русские ошибки', () {
    test('неизвестное имя', () {
      expect(errorMessage('print(неизвестно)'), contains('не найдено'));
    });

    test('деление на ноль', () {
      expect(errorMessage('print(5 / 0)'), contains('Деление на ноль'));
    });

    test('вызов значения, которое не функция', () {
      expect(errorMessage('x = 5\nx()'), contains('не функция'));
    });
  });
}
