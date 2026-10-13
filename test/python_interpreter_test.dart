import 'package:code_kids/python/python_runner.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> run(String code) {
  final r = PythonRunner.run(code);
  if (!r.ok) {
    fail('Неожиданная ошибка: ${r.error}');
  }
  return r.output;
}

List<String> runWith(String code, List<String> inputs) {
  final r = PythonRunner.run(code, inputs: inputs);
  if (!r.ok) {
    fail('Неожиданная ошибка: ${r.error}');
  }
  return r.output;
}

void main() {
  test('print выводит текст', () {
    expect(run("print('Привет')"), ['Привет']);
    expect(run('print("Привет, мир!")'), ['Привет, мир!']);
  });

  test('числа и арифметика', () {
    expect(run('print(2 + 3 * 4)'), ['14']);
    expect(run('print(6 / 3)'), ['2.0']);
    expect(run('print(7 // 2)'), ['3']);
    expect(run('print(7 % 2)'), ['1']);
    expect(run('print(2 ** 10)'), ['1024']);
    expect(run('print(-5 + 2)'), ['-3']);
  });

  test('переменные и строки', () {
    expect(run("имя = 'Аня'\nprint('Привет, ' + имя)"), ['Привет, Аня']);
    expect(run("print('ab' * 3)"), ['ababab']);
    expect(run("print(len('привет'))"), ['6']);
  });

  test('условия if / elif / else', () {
    const code = '''
x = 7
if x > 10:
    print('большое')
elif x > 5:
    print('среднее')
else:
    print('маленькое')
''';
    expect(run(code), ['среднее']);
  });

  test('цикл for с range', () {
    expect(run('for i in range(3):\n    print(i)'), ['0', '1', '2']);
    expect(run('for i in range(1, 4):\n    print(i)'), ['1', '2', '3']);
  });

  test('цикл while и break', () {
    const code = '''
n = 3
while n > 0:
    print(n)
    n = n - 1
''';
    expect(run(code), ['3', '2', '1']);

    const withBreak = '''
for i in range(10):
    if i == 2:
        break
    print(i)
''';
    expect(run(withBreak), ['0', '1']);
  });

  test('списки', () {
    expect(run('a = [1, 2, 3]\nprint(a)'), ['[1, 2, 3]']);
    expect(run('a = [1, 2]\na.append(3)\nprint(a)'), ['[1, 2, 3]']);
    expect(run('a = [10, 20, 30]\nprint(a[-1])'), ['30']);
    expect(run('print(len([1, 2, 3, 4]))'), ['4']);
    expect(run("print(['a', 'b'])"), ["['a', 'b']"]);
  });

  test('функции def / return', () {
    const code = '''
def double(x):
    return x * 2

print(double(4))
''';
    expect(run(code), ['8']);

    const withPrint = '''
def greet(name):
    print('Привет, ' + name)

greet('Ваня')
''';
    expect(run(withPrint), ['Привет, Ваня']);
  });

  test('логические операции и сравнения', () {
    expect(run('print(3 < 5 and 2 > 1)'), ['True']);
    expect(run('print(3 > 5 or 2 > 1)'), ['True']);
    expect(run('print(not False)'), ['True']);
    expect(run('print(1 == 1)'), ['True']);
  });

  test('встроенные функции', () {
    expect(run('print(max(3, 7, 2))'), ['7']);
    expect(run('print(sum([1, 2, 3]))'), ['6']);
    expect(run('print(abs(-4))'), ['4']);
    expect(run("print(int('42') + 1)"), ['43']);
  });

  test('комментарии игнорируются', () {
    expect(run('# это комментарий\nprint(1)  # и это'), ['1']);
  });

  test('вложенные блоки', () {
    const code = '''
for i in range(2):
    for j in range(2):
        print(i * 10 + j)
''';
    expect(run(code), ['0', '1', '10', '11']);
  });

  test('срезы строк', () {
    expect(run("s = 'пирамида'\nprint(s[:4])\nprint(s[-3:])"), ['пира', 'ида']);
    expect(run("print('Привет'[1:4])"), ['рив']);
    expect(run("print('abcdef'[::2])"), ['ace']);
    expect(run("print('abcdef'[::-1])"), ['fedcba']);
    expect(run("print('привет'[:0])"), ['']);
  });

  test('срезы списков', () {
    expect(run('a = [10, 20, 30, 40]\nprint(a[1:3])'), ['[20, 30]']);
    expect(run('a = [10, 20, 30, 40]\nprint(a[:2])'), ['[10, 20]']);
    expect(run('a = [10, 20, 30, 40]\nprint(a[-2:])'), ['[30, 40]']);
  });

  test('словари: создание, доступ, длина, печать', () {
    expect(
      run("d = {'кот': 3, 'пёс': 5}\nprint(d['кот'])\nprint(len(d))"),
      ['3', '2'],
    );
    expect(
      run("d = {}\nd['x'] = 1\nd['y'] = 2\nprint(d)"),
      ["{'x': 1, 'y': 2}"],
    );
    expect(
      run("d = {'a': 1}\nd['a'] = 9\nprint(d['a'])"),
      ['9'],
    );
  });

  test('словари: перебор ключей и методы keys/values/get', () {
    expect(
      run("d = {'a': 1, 'b': 2}\nfor k in d:\n    print(k)"),
      ['a', 'b'],
    );
    expect(run("d = {'a': 1}\nprint(d.keys())"), ["['a']"]);
    expect(run("d = {'a': 1}\nprint(d.values())"), ['[1]']);
    expect(run("d = {'a': 1}\nprint(d.get('b', 0))"), ['0']);
  });

  test('оператор in', () {
    expect(run('print(2 in [1, 2, 3])'), ['True']);
    expect(run('print(5 in [1, 2, 3])'), ['False']);
    expect(run("print('ра' in 'пирамида')"), ['True']);
    expect(run("print('нет' in 'пирамида')"), ['False']);
    expect(run("print('a' not in {'b': 1})"), ['True']);
  });

  test('input() подставляет заготовленные ответы', () {
    expect(
      runWith("имя = input('Имя? ')\nprint('Привет, ' + имя)", ['Аня']),
      ['Имя? ', 'Привет, Аня'],
    );
    expect(
      runWith("x = input()\nprint('Привет, ' + x)", ['Боря']),
      ['Привет, Боря'],
    );
    // Ответов больше нет — программа получает пустую строку.
    expect(runWith("x = input()\nprint('[' + x + ']')", []), ['[]']);
  });

  test('черепашка рисует линии', () {
    final square = PythonRunner.run(
      'for i in range(4):\n    turtle.forward(50)\n    turtle.right(90)',
    );
    expect(square.ok, isTrue, reason: '${square.error}');
    expect(square.turtleSegments.length, 4);
    final first = square.turtleSegments.first;
    expect(first.x1, closeTo(0, 0.001));
    expect(first.y1, closeTo(0, 0.001));
    expect(first.x2, closeTo(50, 0.001));
    expect(first.y2, closeTo(0, 0.001));
  });

  test('черепашка: поднятое перо не рисует', () {
    final r = PythonRunner.run(
      'turtle.penup()\nturtle.forward(50)\nturtle.pendown()\nturtle.forward(50)',
    );
    expect(r.ok, isTrue, reason: '${r.error}');
    expect(r.turtleSegments.length, 1);
  });

  test('ошибка: ключа нет в словаре', () {
    final r = PythonRunner.run("d = {'a': 1}\nprint(d['b'])");
    expect(r.ok, isFalse);
    expect(r.error!.message, contains('нет ключа'));
  });

  test('ошибка: шаг среза равен нулю', () {
    final r = PythonRunner.run("print('abc'[::0])");
    expect(r.ok, isFalse);
    expect(r.error!.message, contains('Шаг среза'));
  });

  // ---- ошибки ----

  test('неизвестное имя даёт ошибку', () {
    final r = PythonRunner.run('print(неизвестно)');
    expect(r.ok, isFalse);
    expect(r.error!.message, contains('не найдено'));
  });

  test('деление на ноль даёт ошибку', () {
    final r = PythonRunner.run('print(5 / 0)');
    expect(r.ok, isFalse);
    expect(r.error!.message, contains('Деление на ноль'));
  });

  test('неверный отступ даёт ошибку', () {
    final r = PythonRunner.run('if True:\n  print(1)\n   print(2)');
    expect(r.ok, isFalse);
  });

  test('бесконечный цикл останавливается', () {
    final r = PythonRunner.run('while True:\n    pass');
    expect(r.ok, isFalse);
    expect(r.error!.message, contains('долго'));
  });

  test('незакрытая скобка даёт понятную ошибку', () {
    final r = PythonRunner.run("print('abc'");
    expect(r.ok, isFalse);
  });
}
