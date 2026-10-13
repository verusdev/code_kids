/// Ошибка выполнения/разбора Python-кода с понятным ребёнку текстом.
class PythonError implements Exception {
  PythonError(this.message, {this.line});

  final String message;
  final int? line;

  @override
  String toString() =>
      line == null ? message : 'Строка $line: $message';
}
