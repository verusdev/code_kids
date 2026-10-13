/// Один урок Python-курса.
class PythonLesson {
  const PythonLesson({
    required this.title,
    required this.goal,
    required this.theory,
    required this.exampleCode,
    required this.task,
    required this.startCode,
    required this.expectedOutput,
    required this.hint,
    this.inputs = const [],
    this.exampleInputs = const [],
    this.drawsTurtle = false,
  });

  final String title;
  final String goal;

  /// Абзацы объяснения.
  final List<String> theory;

  /// Пример кода (можно запустить).
  final String exampleCode;

  /// Текст задания.
  final String task;

  /// Код, который ребёнок видит в редакторе в самом начале.
  final String startCode;

  /// Ожидаемый вывод (сравнивается после нормализации).
  final String expectedOutput;

  /// Подсказка по решению.
  final String hint;

  /// Заранее заготовленные ответы для input() при решении задания:
  /// программа «спрашивает», а приложение подставляет эти значения.
  final List<String> inputs;

  /// Ответы для input() при запуске примера (могут отличаться от задания).
  final List<String> exampleInputs;

  /// Нужно ли показывать холст черепашки (для уроков про turtle).
  final bool drawsTurtle;

  /// Сравнивает вывод программы с ожидаемым (без учёта лишних пробелов в конце).
  bool matches(String actualOutput) =>
      normalize(actualOutput) == normalize(expectedOutput);

  static String normalize(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((l) => l.trimRight())
        .toList();
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n').trim();
  }
}
