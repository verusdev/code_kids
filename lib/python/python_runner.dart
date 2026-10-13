import 'python_error.dart';
import 'python_interpreter.dart';
import 'python_lexer.dart';
import 'python_parser.dart';

/// Результат запуска кода: строки вывода и (возможно) ошибка.
class PythonResult {
  PythonResult({
    required this.output,
    required this.error,
    this.turtleSegments = const [],
  });

  final List<String> output;
  final PythonError? error;

  /// Линии, которые нарисовала черепашка (может быть пусто).
  final List<TurtleSegment> turtleSegments;

  bool get ok => error == null;

  /// Вывод одной строкой (для сравнения с ожидаемым ответом).
  String get outputText => output.join('\n');
}

/// Запускает Python-код ребёнка в безопасной песочнице.
class PythonRunner {
  /// [inputs] — ответы для input(): программа «спрашивает», а мы подставляем.
  static PythonResult run(String source, {List<String> inputs = const []}) {
    final interpreter = PythonInterpreter(inputs: inputs);
    try {
      final tokens = PythonLexer().tokenize(source);
      final program = PythonParser(tokens).parse();
      interpreter.run(program);
      return PythonResult(
        output: List.of(interpreter.output),
        error: null,
        turtleSegments: List.of(interpreter.turtleSegments),
      );
    } on PythonError catch (e) {
      return PythonResult(
        output: List.of(interpreter.output),
        error: e,
        turtleSegments: List.of(interpreter.turtleSegments),
      );
    } catch (e) {
      return PythonResult(
        output: List.of(interpreter.output),
        error: PythonError('Что-то пошло не так: $e'),
        turtleSegments: List.of(interpreter.turtleSegments),
      );
    }
  }
}
