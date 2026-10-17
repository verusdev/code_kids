import 'dart:math' as math;

import 'python_ast.dart';
import 'python_error.dart';

/// Ошибки с типом — чтобы работало `except NameError:` и т.п.
/// Все расширяют PythonError, поэтому текст ошибки для ребёнка прежний.
class _NameErr extends PythonError {
  _NameErr(super.message, {super.line});
}

class _ValueErr extends PythonError {
  _ValueErr(super.message, {super.line});
}

class _ZeroDivErr extends PythonError {
  _ZeroDivErr(super.message, {super.line});
}

class _TypeErr extends PythonError {
  _TypeErr(super.message, {super.line});
}

/// Ошибка про лимиты безопасности (шаги, рекурсия, вывод).
/// НЕ ловится конструкцией try/except — иначе цикл с ошибкой
/// мог бы крутиться вечно и обходить лимиты.
class _LimitErr extends PythonError {
  _LimitErr(super.message, {super.line});
}

/// Пользовательская функция, объявленная через `def`.
class PyFunction {
  PyFunction(this.name, this.params, this.body, this.closure);

  final String name;
  final List<String> params;
  final List<Node> body;
  final PyEnv closure;
}

/// Встроенная функция (print, len, range, ...).
class PyBuiltin {
  PyBuiltin(this.name, this.fn);

  final String name;
  final Object? Function(List<Object?> args) fn;
}

/// Окружение (таблица имён) со ссылкой на внешний скоуп.
class PyEnv {
  PyEnv([this.parent]);

  final PyEnv? parent;
  final Map<String, Object?> vars = {};

  void define(String name, Object? value) => vars[name] = value;

  Object? get(String name) {
    PyEnv? env = this;
    while (env != null) {
      if (env.vars.containsKey(name)) return env.vars[name];
      env = env.parent;
    }
    return _missing;
  }

  static const Object _missing = Object();
}

/// Словарь Python: хранит пары «ключ → значение».
class PyDict {
  final Map<Object?, Object?> entries = <Object?, Object?>{};

  int get length => entries.length;
}

/// Отрезок линии, который нарисовала черепашка (координаты в «пикселях»).
class TurtleSegment {
  TurtleSegment(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

/// Черепашка: ходит с пером и оставляет за собой линии.
class PyTurtle {
  PyTurtle(this.segments);

  /// Куда складывать нарисованные отрезки.
  final List<TurtleSegment> segments;

  double x = 0;
  double y = 0;

  /// Угол в градусах: 0 — вправо, 90 — вниз (координаты экрана).
  double angle = 0;

  bool penDown = true;
}

/// Встроенный модуль `import random`: randint, choice, random.
class PyRandomModule {
  final math.Random _rnd = math.Random();

  /// Вызов функции модуля: random.randint(1, 10) и т.п.
  Object? call(String name, List<Object?> args, int line) {
    switch (name) {
      case 'randint':
        if (args.length != 2) {
          throw PythonError('random.randint() принимает два числа', line: line);
        }
        final a = _asIntArg(args[0], 'random.randint', line);
        final b = _asIntArg(args[1], 'random.randint', line);
        if (a > b) {
          throw _ValueErr(
            'random.randint: первое число ($a) не может быть больше второго ($b)',
            line: line,
          );
        }
        return _rnd.nextInt(b - a + 1) + a;
      case 'choice':
        if (args.length != 1) {
          throw PythonError('random.choice() принимает один список', line: line);
        }
        final list = args[0];
        if (list is! List) {
          throw _TypeErr('random.choice() ждёт список', line: line);
        }
        if (list.isEmpty) {
          throw _ValueErr('random.choice(): список пуст', line: line);
        }
        return list[_rnd.nextInt(list.length)];
      case 'random':
        if (args.isNotEmpty) {
          throw PythonError('random.random() не принимает значений', line: line);
        }
        return _rnd.nextDouble();
    }
    throw PythonError('У random нет функции «$name»', line: line);
  }

  int _asIntArg(Object? v, String where, int line) {
    if (v is int) return v;
    if (v is double) return v.truncate();
    throw _TypeErr('$where ждёт целые числа, а получено ${pyType(v)}', line: line);
  }
}

// Внутренние сигналы управления потоком.
class _Break {
  const _Break();
}

class _Continue {
  const _Continue();
}

class _Return {
  _Return(this.value);

  final Object? value;
}

/// Исполнитель Python-подмножества: обходит дерево и выполняет код.
class PythonInterpreter {
  PythonInterpreter({
    this.inputs = const [],
    this.maxSteps = 300000,
    this.maxOutputLines = 500,
    this.maxDepth = 60,
  });

  /// Ответы, которые «вводит» пользователь, когда программа зовёт input().
  final List<String> inputs;
  int _inputIndex = 0;

  final int maxSteps;
  final int maxOutputLines;
  final int maxDepth;

  final List<String> output = [];

  /// Всё, что нарисовала черепашка (turtle.forward(...)).
  final List<TurtleSegment> turtleSegments = [];
  int _steps = 0;
  int _depth = 0;

  void _tick(int line) {
    _steps++;
    if (_steps > maxSteps) {
      throw _LimitErr(
        'Программа слишком долго работает — возможно, бесконечный цикл. '
        'Проверь условие или счётчик.',
        line: line,
      );
    }
  }

  void run(Program program) {
    final env = PyEnv();
    _installBuiltins(env);
    for (final stmt in program.body) {
      _exec(stmt, env);
    }
  }

  // ---------- операторы ----------

  void _exec(Node node, PyEnv env) {
    _tick(node.line);

    if (node is ExprStmt) {
      _eval(node.expr, env);
      return;
    }
    if (node is AssignNode) {
      env.define(node.name, _eval(node.value, env));
      return;
    }
    if (node is AssignIndexNode) {
      if (node.index is SliceNode) {
        throw PythonError(
          'Пока нельзя менять сразу кусочек — меняй по одному элементу',
          line: node.line,
        );
      }
      final target = _eval(node.target, env);
      final key = _eval(node.index, env);
      final value = _eval(node.value, env);
      _setIndex(target, key, value, node.line);
      return;
    }
    if (node is IfNode) {
      if (_truthy(_eval(node.condition, env))) {
        _execBlock(node.body, env);
      } else {
        _execBlock(node.orelse, env);
      }
      return;
    }
    if (node is WhileNode) {
      while (_truthy(_eval(node.condition, env))) {
        _tick(node.line);
        try {
          _execBlock(node.body, env);
        } on _Break {
          break;
        } on _Continue {
          continue;
        }
      }
      return;
    }
    if (node is ForNode) {
      final iterable = _eval(node.iterable, env);
      final items = _asIterable(iterable, node.line);
      for (final item in items) {
        env.define(node.variable, item);
        try {
          _execBlock(node.body, env);
        } on _Break {
          break;
        } on _Continue {
          continue;
        }
      }
      return;
    }
    if (node is FuncDefNode) {
      env.define(node.name, PyFunction(node.name, node.params, node.body, env));
      return;
    }
    if (node is ReturnNode) {
      throw _Return(node.value == null ? null : _eval(node.value!, env));
    }
    if (node is BreakNode) {
      throw const _Break();
    }
    if (node is ContinueNode) {
      throw const _Continue();
    }
    if (node is PassNode) {
      return;
    }
    if (node is TryExceptNode) {
      try {
        _execBlock(node.tryBody, env);
      } on _LimitErr {
        // Лимиты безопасности не обходятся через except.
        rethrow;
      } on PythonError catch (e) {
        if (!_matchesExcept(e, node.exceptType)) rethrow;
        _execBlock(node.exceptBody, env);
      }
      return;
    }
    if (node is ImportNode) {
      if (node.module != 'random') {
        throw PythonError(
          'Пока поддерживается только import random',
          line: node.line,
        );
      }
      env.define('random', PyRandomModule());
      return;
    }
    throw PythonError('Неподдерживаемая конструкция', line: node.line);
  }

  void _execBlock(List<Node> body, PyEnv env) {
    for (final stmt in body) {
      _exec(stmt, env);
    }
  }

  /// Совпадает ли ошибка с типом в `except ИмяОшибки:`.
  /// `exceptType == null` — голый `except:` (ловит любую ошибку).
  bool _matchesExcept(PythonError e, String? exceptType) {
    if (exceptType == null) return true;
    switch (exceptType) {
      case 'NameError':
        return e is _NameErr;
      case 'ValueError':
        return e is _ValueErr;
      case 'ZeroDivisionError':
        return e is _ZeroDivErr;
      case 'TypeError':
        return e is _TypeErr;
    }
    return true;
  }

  List<Object?> _asIterable(Object? value, int line) {
    if (value is List) return value;
    if (value is String) return value.split('');
    if (value is PyDict) return value.entries.keys.toList();
    throw PythonError(
      'Можно перебирать только список, строку или словарь, а не ${pyType(value)}',
      line: line,
    );
  }

  // ---------- выражения ----------

  Object? _eval(Node node, PyEnv env) {
    if (node is NumNode) return node.value;
    if (node is StrNode) return node.value;
    if (node is BoolNode) return node.value;
    if (node is NoneNode) return null;
    if (node is NameNode) {
      final v = env.get(node.name);
      if (identical(v, PyEnv._missing)) {
        throw _NameErr(
          'Имя «${node.name}» не найдено. Проверь, что переменная создана.',
          line: node.line,
        );
      }
      return v;
    }
    if (node is ListNode) {
      return node.elements.map((e) => _eval(e, env)).toList();
    }
    if (node is DictNode) {
      final dict = PyDict();
      for (int i = 0; i < node.keys.length; i++) {
        final key = _eval(node.keys[i], env);
        dict.entries[_hashKey(key, node.line)] = _eval(node.values[i], env);
      }
      return dict;
    }
    if (node is BinOpNode) {
      return _binop(node.op, _eval(node.left, env), _eval(node.right, env), node.line);
    }
    if (node is UnaryOpNode) {
      final v = _eval(node.operand, env);
      switch (node.op) {
        case '-':
          return -_asNum(v, node.line);
        case '+':
          return _asNum(v, node.line);
        case 'not':
          return !_truthy(v);
      }
    }
    if (node is BoolOpNode) {
      final left = _eval(node.left, env);
      if (node.op == 'and') {
        return _truthy(left) ? _eval(node.right, env) : left;
      }
      return _truthy(left) ? left : _eval(node.right, env);
    }
    if (node is CompareNode) {
      return _compare(node, env);
    }
    if (node is IndexNode) {
      final target = _eval(node.target, env);
      if (node.index is SliceNode) {
        return _slice(target, node.index as SliceNode, env, node.line);
      }
      final index = _eval(node.index, env);
      return _index(target, index, node.line);
    }
    if (node is CallNode) {
      return _evalCall(node, env);
    }
    if (node is AttributeNode) {
      throw PythonError(
        'Метод «${node.name}» нужно вызвать со скобками, например: '
        '${_describe(node.target)}.${node.name}()',
        line: node.line,
      );
    }
    throw PythonError('Неподдерживаемое выражение', line: node.line);
  }

  String _describe(Node node) =>
      node is NameNode ? node.name : 'объект';

  Object? _evalCall(CallNode node, PyEnv env) {
    // Вызов метода: объект.метод(аргументы)
    if (node.callee is AttributeNode) {
      final attr = node.callee as AttributeNode;
      final target = _eval(attr.target, env);
      final args = node.args.map((a) => _eval(a, env)).toList();
      return _callMethod(target, attr.name, args, node.line);
    }
    final callee = _eval(node.callee, env);
    final args = node.args.map((a) => _eval(a, env)).toList();
    return _call(callee, args, node.line, node.callee);
  }

  Object? _call(Object? callee, List<Object?> args, int line, Node calleeNode) {
    if (callee is PyBuiltin) {
      return callee.fn(args);
    }
    if (callee is PyRandomModule) {
      // Просто random() — то же самое, что random.random()
      return callee.call('random', args, line);
    }
    if (callee is PyFunction) {
      if (args.length != callee.params.length) {
        throw PythonError(
          'Функция ${callee.name}() ждёт ${callee.params.length} '
          'значений, а получила ${args.length}',
          line: line,
        );
      }
      _depth++;
      if (_depth > maxDepth) {
        _depth--;
        throw _LimitErr(
          'Слишком много вложенных вызовов. Возможно, функция вызывает саму себя.',
          line: line,
        );
      }
      final local = PyEnv(callee.closure);
      for (int i = 0; i < callee.params.length; i++) {
        local.define(callee.params[i], args[i]);
      }
      try {
        _execBlock(callee.body, local);
        return null;
      } on _Return catch (r) {
        return r.value;
      } finally {
        _depth--;
      }
    }
    throw PythonError(
      '«${calleeNode is NameNode ? calleeNode.name : 'значение'}» — не функция, '
      'её нельзя вызвать',
      line: line,
    );
  }

  Object? _callMethod(Object? target, String name, List<Object?> args, int line) {
    if (target is List) {
      switch (name) {
        case 'append':
          if (args.length != 1) {
            throw PythonError('append() принимает одно значение', line: line);
          }
          target.add(args[0]);
          return null;
        case 'pop':
          if (target.isEmpty) {
            throw PythonError('Список пуст — нечего удалять', line: line);
          }
          return target.removeLast();
        case 'insert':
          if (args.length != 2) {
            throw PythonError('insert() принимает два значения', line: line);
          }
          final i = _asInt(args[0], line);
          target.insert(i.clamp(0, target.length), args[1]);
          return null;
        case 'clear':
          target.clear();
          return null;
      }
    }
    if (target is String) {
      switch (name) {
        case 'upper':
          return target.toUpperCase();
        case 'lower':
          return target.toLowerCase();
        case 'strip':
          return target.trim();
        case 'replace':
          if (args.length != 2 || args[0] is! String || args[1] is! String) {
            throw PythonError(
              'replace() принимает два кусочка текста: replace(что, на что)',
              line: line,
            );
          }
          final from = args[0] as String;
          if (from.isEmpty) {
            throw _ValueErr('replace() не может искать пустой кусочек', line: line);
          }
          return target.replaceAll(from, args[1] as String);
        case 'count':
          if (args.length != 1 || args[0] is! String) {
            throw PythonError('count() принимает один кусочек текста', line: line);
          }
          return _countOccurrences(target, args[0] as String);
        case 'split':
          if (args.length > 1) {
            throw PythonError(
              'split() принимает не больше одного разделителя',
              line: line,
            );
          }
          if (args.isEmpty) {
            // Без аргумента делим по любым пробелам, как в Python.
            if (target.trim().isEmpty) return <String>[];
            return target
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .toList();
          }
          if (args[0] is! String) {
            throw _TypeErr('split() ждёт текст-разделитель', line: line);
          }
          final sep = args[0] as String;
          if (sep.isEmpty) {
            throw _ValueErr('Разделитель не может быть пустым', line: line);
          }
          return target.split(sep);
        case 'join':
          if (args.length != 1 || args[0] is! List) {
            throw PythonError('join() принимает список строк', line: line);
          }
          final parts = args[0] as List;
          for (final p in parts) {
            if (p is! String) {
              throw _TypeErr(
                'join() склеивает только строки, а внутри списка ${pyType(p)}',
                line: line,
              );
            }
          }
          return parts.cast<String>().join(target);
      }
    }
    if (target is PyDict) {
      switch (name) {
        case 'keys':
          return target.entries.keys.toList();
        case 'values':
          return target.entries.values.toList();
        case 'get':
          if (args.isEmpty || args.length > 2) {
            throw PythonError(
              'get() принимает ключ и, может быть, запасное значение',
              line: line,
            );
          }
          final key = _hashKey(args[0], line);
          if (target.entries.containsKey(key)) return target.entries[key];
          return args.length == 2 ? args[1] : null;
        case 'clear':
          target.entries.clear();
          return null;
      }
    }
    if (target is PyTurtle) {
      return _turtleMethod(target, name, args, line);
    }
    if (target is PyRandomModule) {
      return target.call(name, args, line);
    }
    throw PythonError(
      'У ${pyType(target)} нет метода «$name»',
      line: line,
    );
  }

  Object? _turtleMethod(PyTurtle t, String name, List<Object?> args, int line) {
    switch (name) {
      case 'forward':
      case 'вперёд':
      case 'fd':
        _turtleMove(t, _asNum(_oneArg(args, 'forward'), line).toDouble(), line);
        return null;
      case 'backward':
      case 'back':
      case 'назад':
        _turtleMove(t, -_asNum(_oneArg(args, 'backward'), line).toDouble(), line);
        return null;
      case 'right':
      case 'направо':
      case 'rt':
        t.angle += _asNum(_oneArg(args, 'right'), line).toDouble();
        return null;
      case 'left':
      case 'налево':
      case 'lt':
        t.angle -= _asNum(_oneArg(args, 'left'), line).toDouble();
        return null;
      case 'penup':
      case 'поднять':
      case 'up':
        t.penDown = false;
        return null;
      case 'pendown':
      case 'опустить':
      case 'down':
        t.penDown = true;
        return null;
      case 'goto':
      case 'перейти':
        if (args.length != 2) {
          throw PythonError('goto() принимает два числа', line: line);
        }
        _turtleLineTo(
          t,
          _asNum(args[0], line).toDouble(),
          _asNum(args[1], line).toDouble(),
          line,
        );
        return null;
    }
    throw PythonError('Черепашка не знает команду «$name»', line: line);
  }

  Object? _oneArg(List<Object?> args, String name) {
    if (args.length != 1) {
      throw PythonError('$name() принимает одно число');
    }
    return args[0];
  }

  /// Сколько раз кусочек встречается в строке (не внахлёст, как в Python).
  int _countOccurrences(String text, String part) {
    if (part.isEmpty) return 0;
    int count = 0;
    int from = 0;
    while (true) {
      final i = text.indexOf(part, from);
      if (i < 0) return count;
      count++;
      from = i + part.length;
    }
  }

  void _turtleMove(PyTurtle t, double distance, int line) {
    final rad = t.angle * math.pi / 180.0;
    _turtleLineTo(
      t,
      t.x + math.cos(rad) * distance,
      t.y + math.sin(rad) * distance,
      line,
    );
  }

  void _turtleLineTo(PyTurtle t, double nx, double ny, int line) {
    if (t.penDown) {
      if (turtleSegments.length > 4000) {
        throw _LimitErr(
          'Черепашка нарисовала слишком много линий',
          line: line,
        );
      }
      turtleSegments.add(TurtleSegment(t.x, t.y, nx, ny));
    }
    t.x = nx;
    t.y = ny;
  }

  /// Ключ словаря не может быть списком/словарём; целые дроби приводим к int.
  Object? _hashKey(Object? value, int line) {
    if (value is List ||
        value is PyDict ||
        value is PyTurtle ||
        value is PyFunction ||
        value is PyBuiltin) {
      throw PythonError('Ключом словаря не может быть ${pyType(value)}', line: line);
    }
    if (value is double &&
        value.isFinite &&
        value == value.roundToDouble() &&
        value.abs() < 1e16) {
      return value.toInt();
    }
    return value;
  }

  // ---------- арифметика и сравнения ----------

  Object? _binop(String op, Object? a, Object? b, int line) {
    if (op == '+') {
      if (a is String && b is String) return a + b;
      if (a is List && b is List) return [...a, ...b];
      if (a is num && b is num) return _addNums(a, b);
      throw _TypeErr(
        'Нельзя сложить ${pyType(a)} и ${pyType(b)}',
        line: line,
      );
    }
    if (op == '*') {
      if (a is String && b is num) return _repeat(a, _asInt(b, line));
      if (b is String && a is num) return _repeat(b, _asInt(a, line));
      if (a is List && b is num) {
        final n = _asInt(b, line);
        return [for (int i = 0; i < n; i++) ...a];
      }
      if (a is num && b is num) return _mulNums(a, b);
      throw _TypeErr('Нельзя умножить ${pyType(a)} на ${pyType(b)}', line: line);
    }
    final x = _asNum(a, line);
    final y = _asNum(b, line);
    switch (op) {
      case '-':
        return x - y;
      case '/':
        if (y == 0) {
          throw _ZeroDivErr('Деление на ноль', line: line);
        }
        return x / y;
      case '//':
        if (y == 0) {
          throw _ZeroDivErr('Деление на ноль', line: line);
        }
        final r = x / y;
        return r.floor();
      case '%':
        if (y == 0) {
          throw _ZeroDivErr('Деление на ноль', line: line);
        }
        final r = x % y;
        return r is double && r == r.roundToDouble() ? r.round() : r;
      case '**':
        return _pow(x, y, line);
    }
    throw PythonError('Неизвестная операция «$op»', line: line);
  }

  num _addNums(num a, num b) {
    if (a is int && b is int) return a + b;
    return a.toDouble() + b.toDouble();
  }

  num _mulNums(num a, num b) {
    if (a is int && b is int) return a * b;
    return a.toDouble() * b.toDouble();
  }

  String _repeat(String s, int n) {
    if (n <= 0) return '';
    return List.filled(n, s).join();
  }

  num _pow(num base, num exp, int line) {
    if (base is int && exp is int && exp >= 0 && exp <= 63) {
      int r = 1;
      for (int i = 0; i < exp; i++) {
        r *= base;
      }
      return r;
    }
    final r = math.pow(base, exp).toDouble();
    if (r.isNaN || r.isInfinite) {
      throw PythonError('Слишком большое число', line: line);
    }
    return r;
  }

  Object? _compare(CompareNode node, PyEnv env) {
    var left = _eval(node.left, env);
    for (int i = 0; i < node.ops.length; i++) {
      final right = _eval(node.comparators[i], env);
      if (!_compareOne(node.ops[i], left, right, node.line)) {
        return false;
      }
      left = right;
    }
    return true;
  }

  bool _compareOne(String op, Object? a, Object? b, int line) {
    switch (op) {
      case '==':
        return _equals(a, b);
      case '!=':
        return !_equals(a, b);
    }
    if (op == 'in') return _contains(b, a, line);
    if (op == 'not in') return !_contains(b, a, line);
    if (a is num && b is num) {
      switch (op) {
        case '<':
          return a < b;
        case '>':
          return a > b;
        case '<=':
          return a <= b;
        case '>=':
          return a >= b;
      }
    }
    if (a is String && b is String) {
      final c = a.compareTo(b);
      switch (op) {
        case '<':
          return c < 0;
        case '>':
          return c > 0;
        case '<=':
          return c <= 0;
        case '>=':
          return c >= 0;
      }
    }
    throw PythonError(
      'Нельзя сравнить ${pyType(a)} и ${pyType(b)} знаком «$op»',
      line: line,
    );
  }

  bool _equals(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_equals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is PyDict && b is PyDict) {
      if (a.entries.length != b.entries.length) return false;
      for (final e in a.entries.entries) {
        if (!b.entries.containsKey(e.key) ||
            !_equals(b.entries[e.key], e.value)) {
          return false;
        }
      }
      return true;
    }
    if (a is num && b is num) return a == b;
    return a == b;
  }

  Object? _index(Object? target, Object? index, int line) {
    if (target is PyDict) {
      final key = _hashKey(index, line);
      if (!target.entries.containsKey(key)) {
        throw PythonError(
          'В словаре нет ключа ${pyStr(index)}',
          line: line,
        );
      }
      return target.entries[key];
    }
    final i = _asInt(index, line);
    if (target is List) {
      final idx = i < 0 ? target.length + i : i;
      if (idx < 0 || idx >= target.length) {
        throw PythonError(
          'Индекс $i вне списка (в нём ${target.length} элементов)',
          line: line,
        );
      }
      return target[idx];
    }
    if (target is String) {
      final idx = i < 0 ? target.length + i : i;
      if (idx < 0 || idx >= target.length) {
        throw PythonError('Индекс $i вне строки', line: line);
      }
      return target[idx];
    }
    throw PythonError('Индексы работают только для списка, строки и словаря', line: line);
  }

  void _setIndex(Object? target, Object? index, Object? value, int line) {
    if (target is List) {
      final i = _asInt(index, line);
      final idx = i < 0 ? target.length + i : i;
      if (idx < 0 || idx >= target.length) {
        throw PythonError(
          'Индекс $i вне списка (в нём ${target.length} элементов)',
          line: line,
        );
      }
      target[idx] = value;
      return;
    }
    if (target is PyDict) {
      target.entries[_hashKey(index, line)] = value;
      return;
    }
    throw PythonError('Менять по индексу можно только список и словарь', line: line);
  }

  /// Срез строки или списка: `s[1:3]`, `s[:2]`, `s[2:]`, `s[::2]`, `s[::-1]`.
  Object? _slice(Object? target, SliceNode node, PyEnv env, int line) {
    final int length;
    if (target is String) {
      length = target.length;
    } else if (target is List) {
      length = target.length;
    } else {
      throw PythonError(
        'Срезы (например, слово[1:3]) работают только для строки и списка',
        line: line,
      );
    }
    final indices = _sliceRange(length, node, env, line);
    if (target is String) {
      return indices.map((i) => target[i]).join();
    }
    return indices.map((i) => (target as List)[i]).toList();
  }

  List<int> _sliceRange(int length, SliceNode node, PyEnv env, int line) {
    int? rawStart;
    int? rawStop;
    if (node.start != null) rawStart = _asInt(_eval(node.start!, env), line);
    if (node.stop != null) rawStop = _asInt(_eval(node.stop!, env), line);
    final step =
        node.step == null ? 1 : _asInt(_eval(node.step!, env), line);
    if (step == 0) {
      throw PythonError('Шаг среза не может быть нулём', line: line);
    }
    final out = <int>[];
    if (step > 0) {
      int start = rawStart == null ? 0 : (rawStart < 0 ? rawStart + length : rawStart);
      int stop = rawStop == null ? length : (rawStop < 0 ? rawStop + length : rawStop);
      if (start < 0) start = 0;
      if (start > length) start = length;
      if (stop < 0) stop = 0;
      if (stop > length) stop = length;
      for (int i = start; i < stop; i += step) {
        out.add(i);
        if (out.length > 100000) break;
      }
    } else {
      int start =
          rawStart == null ? length - 1 : (rawStart < 0 ? rawStart + length : rawStart);
      int stop = rawStop == null ? -1 : (rawStop < 0 ? rawStop + length : rawStop);
      if (start < -1) start = -1;
      if (start > length - 1) start = length - 1;
      if (stop < -1) stop = -1;
      if (stop > length - 1) stop = length - 1;
      for (int i = start; i > stop; i += step) {
        out.add(i);
        if (out.length > 100000) break;
      }
    }
    return out;
  }

  bool _contains(Object? container, Object? item, int line) {
    if (container is String) {
      if (item is! String) {
        throw PythonError('В строке можно искать только текст', line: line);
      }
      return container.contains(item);
    }
    if (container is List) {
      for (final e in container) {
        if (_equals(e, item)) return true;
      }
      return false;
    }
    if (container is PyDict) {
      return container.entries.containsKey(_hashKey(item, line));
    }
    throw PythonError(
      'Искать «in» можно в строке, списке или словаре',
      line: line,
    );
  }

  // ---------- помощники ----------

  num _asNum(Object? v, int line) {
    if (v is num) return v;
    throw _TypeErr('Ожидалось число, а получено ${pyType(v)}', line: line);
  }

  int _asInt(Object? v, int line) {
    if (v is int) return v;
    if (v is double) return v.truncate();
    if (v is bool) return v ? 1 : 0;
    throw _TypeErr('Ожидалось целое число, а получено ${pyType(v)}', line: line);
  }

  bool _truthy(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    if (v is PyDict) return v.entries.isNotEmpty;
    return true;
  }

  // ---------- встроенные функции ----------

  void _installBuiltins(PyEnv env) {
    env.define('print', PyBuiltin('print', (args) {
      if (output.length >= maxOutputLines) {
        throw _LimitErr('Слишком много строк вывода');
      }
      output.add(args.map(pyStr).join(' '));
      return null;
    }));
    env.define('len', PyBuiltin('len', (args) {
      _arity(args, 1, 'len');
      final v = args[0];
      if (v is String) return v.length;
      if (v is List) return v.length;
      if (v is PyDict) return v.length;
      throw _TypeErr('len() работает только со строкой, списком или словарём');
    }));
    env.define('range', PyBuiltin('range', (args) {
      if (args.isEmpty || args.length > 3) {
        throw PythonError('range() принимает от 1 до 3 чисел');
      }
      final nums = args.map((a) => _asNum(a, 0)).toList();
      int start = 0;
      int stop = 0;
      int step = 1;
      if (nums.length == 1) {
        stop = nums[0].toInt();
      } else {
        start = nums[0].toInt();
        stop = nums[1].toInt();
        if (nums.length == 3) step = nums[2].toInt();
      }
      if (step == 0) {
        throw PythonError('Шаг в range() не может быть нулём');
      }
      final list = <int>[];
      if (step > 0) {
        for (int i = start; i < stop; i += step) {
          list.add(i);
          if (list.length > 100000) break;
        }
      } else {
        for (int i = start; i > stop; i += step) {
          list.add(i);
          if (list.length > 100000) break;
        }
      }
      return list;
    }));
    env.define('str', PyBuiltin('str', (args) {
      _arity(args, 1, 'str');
      return pyStr(args[0]);
    }));
    env.define('int', PyBuiltin('int', (args) {
      _arity(args, 1, 'int');
      final v = args[0];
      if (v is int) return v;
      if (v is double) return v.truncate();
      if (v is bool) return v ? 1 : 0;
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        if (parsed == null) {
          throw _ValueErr('int() не может превратить «$v» в число');
        }
        return parsed;
      }
      throw PythonError('int() не умеет работать с ${pyType(v)}');
    }));
    env.define('abs', PyBuiltin('abs', (args) {
      _arity(args, 1, 'abs');
      return _asNum(args[0], 0).abs();
    }));
    env.define('min', PyBuiltin('min', (args) {
      final nums = _flatten(args);
      if (nums.isEmpty) throw PythonError('min() нужен хотя бы один аргумент');
      return nums.reduce((a, b) => a < b ? a : b);
    }));
    env.define('max', PyBuiltin('max', (args) {
      final nums = _flatten(args);
      if (nums.isEmpty) throw PythonError('max() нужен хотя бы один аргумент');
      return nums.reduce((a, b) => a > b ? a : b);
    }));
    env.define('sum', PyBuiltin('sum', (args) {
      _arity(args, 1, 'sum');
      final v = args[0];
      if (v is! List) throw PythonError('sum() принимает список чисел');
      num total = 0;
      for (final e in v) {
        total = _addNums(total, _asNum(e, 0));
      }
      return total;
    }));
    // sorted(список) — новый отсортированный список (исходный не меняется).
    env.define('sorted', PyBuiltin('sorted', (args) {
      _arity(args, 1, 'sorted');
      final v = args[0];
      if (v is! List) {
        throw _TypeErr('sorted() принимает список');
      }
      final copy = List<Object?>.of(v);
      copy.sort((a, b) {
        if (a is num && b is num) return a.compareTo(b);
        if (a is String && b is String) return a.compareTo(b);
        throw _TypeErr(
          'sorted() не умеет сравнивать ${pyType(a)} и ${pyType(b)} — '
          'в одном списке должны быть только числа или только строки',
        );
      });
      return copy;
    }));
    // input(...) задаёт вопрос и получает заранее заготовленный ответ.
    // Если ответов больше нет — возвращает пустую строку.
    env.define('input', PyBuiltin('input', (args) {
      if (args.length > 1) {
        throw PythonError('input() принимает не больше одного вопроса');
      }
      if (args.isNotEmpty && pyStr(args[0]).isNotEmpty) {
        if (output.length >= maxOutputLines) {
          throw _LimitErr('Слишком много строк вывода');
        }
        output.add(pyStr(args[0]));
      }
      if (_inputIndex >= inputs.length) return '';
      return inputs[_inputIndex++];
    }));
    env.define('turtle', PyTurtle(turtleSegments));
  }

  List<num> _flatten(List<Object?> args) {
    final out = <num>[];
    for (final a in args) {
      if (a is List) {
        out.addAll(a.map((e) => _asNum(e, 0)));
      } else {
        out.add(_asNum(a, 0));
      }
    }
    return out;
  }

  void _arity(List<Object?> args, int n, String name) {
    if (args.length != n) {
      throw PythonError('$name() принимает ровно $n значение(я)');
    }
  }
}

/// Преобразование значения в текст (как `str()` в Python).
String pyStr(Object? v) {
  if (v == null) return 'None';
  if (v is bool) return v ? 'True' : 'False';
  if (v is String) return v;
  if (v is List) return '[${v.map(pyRepr).join(', ')}]';
  if (v is PyDict) {
    return '{${v.entries.entries.map((e) => '${pyRepr(e.key)}: ${pyRepr(e.value)}').join(', ')}}';
  }
  if (v is PyFunction) return '<функция ${v.name}>';
  if (v is PyTurtle) return '<черепашка>';
  if (v is PyRandomModule) return '<модуль random>';
  if (v is double) {
    if (v.isFinite && v == v.roundToDouble() && v.abs() < 1e16) {
      return v.toStringAsFixed(1);
    }
    return v.toString();
  }
  return v.toString();
}

/// Как элемент внутри списка (строки — в кавычках).
String pyRepr(Object? v) {
  if (v is String) return "'$v'";
  return pyStr(v);
}

/// Название типа значения для понятных сообщений об ошибке.
String pyType(Object? v) {
  if (v == null) return 'пустое значение';
  if (v is bool) return 'логическое значение';
  if (v is int || v is double) return 'число';
  if (v is String) return 'строка';
  if (v is List) return 'список';
  if (v is PyDict) return 'словарь';
  if (v is PyFunction) return 'функция';
  if (v is PyTurtle) return 'черепашка';
  if (v is PyRandomModule) return 'модуль random';
  return 'значение';
}
