import 'package:flutter/material.dart';

import '../../python/python_runner.dart';
import '../../services/turtle_gallery_service.dart';
import '../../widgets/kid_button.dart';
import '../../widgets/python_code_editor.dart';
import 'turtle_gallery_screen.dart';

/// Свободная Python-песочница: пиши любой код и запускай, без заданий.
///
/// Если программа рисует черепашкой — рисунок можно сохранить
/// в галерею ([TurtleGalleryScreen]).
class PythonSandboxScreen extends StatefulWidget {
  const PythonSandboxScreen({super.key});

  @override
  State<PythonSandboxScreen> createState() => _PythonSandboxScreenState();
}

/// Крупная кнопка-заготовка: вставляет стартовый код в редактор.
class _SandboxExample {
  const _SandboxExample(this.label, this.code);

  final String label;
  final String code;
}

class _PythonSandboxScreenState extends State<PythonSandboxScreen> {
  static const Color _accent = Color(0xFF3776AB);

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  PythonResult? _result;

  static const List<_SandboxExample> _examples = [
    _SandboxExample(
      '👋 Привет',
      'print("Привет, мир!")\nprint("Я учусь программировать!")',
    ),
    _SandboxExample(
      '⬜ Квадрат черепашкой',
      'for i in range(4):\n'
          '    turtle.forward(80)\n'
          '    turtle.right(90)\n'
          '\n'
          'print("Готово!")',
    ),
    _SandboxExample(
      '🌀 Спираль',
      'for i in range(18):\n'
          '    turtle.forward(10 + i * 6)\n'
          '    turtle.right(100)\n',
    ),
    _SandboxExample(
      '🔢 Угадай число',
      'import random\n'
          'загаданное = random.randint(1, 10)\n'
          'ч = int(input("Твоё число: "))\n'
          'if ч == загаданное:\n'
          '    print("Угадал!")\n'
          'elif ч < загаданное:\n'
          '    print("Больше!")\n'
          'else:\n'
          '    print("Меньше!")',
    ),
    _SandboxExample(
      '📚 Список и цикл',
      'фрукты = ["яблоко", "банан", "груша"]\n'
          'for фрукт in фрукты:\n'
          '    print("Я люблю " + фрукт)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Перечитываем галерею на случай смены профиля.
    TurtleGalleryService.instance.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasDrawing => _result?.turtleSegments.isNotEmpty ?? false;

  /// Запуск кода. Если программа зовёт input() — спрашиваем ответы
  /// диалогами, а потом запускаем с готовыми ответами.
  Future<void> _run() async {
    final source = _controller.text;
    final askCount = RegExp(r'\binput\s*\(').allMatches(source).length;
    final inputs = <String>[];
    for (var i = 0; i < askCount; i++) {
      final answer = await _askInput(number: i + 1, total: askCount);
      if (answer == null) return; // ребёнок отменил запуск
      inputs.add(answer);
    }
    if (!mounted) return;
    final result = PythonRunner.run(source, inputs: inputs);
    if (!mounted) return;
    setState(() => _result = result);
  }

  /// Диалог ввода ответа для input().
  Future<String?> _askInput({required int number, required int total}) {
    final inputController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          total > 1 ? 'Ответ №$number из $total' : 'Программа спрашивает',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: inputController,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Введи ответ…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          KidButton(
            label: 'Готово',
            color: _accent,
            onPressed: () => Navigator.of(context).pop(inputController.text),
          ),
        ],
      ),
    );
  }

  /// Сохранение рисунка черепашки в галерею.
  Future<void> _saveDrawing() async {
    final segments = _result?.turtleSegments;
    if (segments == null || segments.isEmpty) return;
    final service = TurtleGalleryService.instance;
    final suggested = 'Рисунок ${service.drawings.length + 1}';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(suggested: suggested),
    );
    if (name == null || !mounted) return;
    await service.add(name, segments);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Рисунок «$name» сохранён! 🎨'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clear() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Песочница'),
        actions: [
          IconButton(
            tooltip: 'Галерея рисунков',
            iconSize: 28,
            icon: const Icon(Icons.image_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TurtleGalleryScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _header(),
          const SizedBox(height: 14),
          _examplesCard(),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PythonCodeEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  onRun: _run,
                  result: _result,
                  consolePlaceholder: 'Нажми «Запустить» — тут появится вывод…',
                  turtleSegments:
                      _hasDrawing ? _result!.turtleSegments : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: KidButton(
                        label: 'Сохранить рисунок',
                        emoji: '🖼',
                        color: const Color(0xFF00B894),
                        expand: true,
                        onPressed: _hasDrawing ? _saveDrawing : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KidButton(
                        label: 'Очистить',
                        icon: Icons.refresh_rounded,
                        color: Colors.grey.shade600,
                        expand: true,
                        onPressed: _clear,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Шапка с маскотом-подсказкой.
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🐢', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Пиши любой код и запускай!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Тут не надо решать задания — просто пробуй команды '
                  'и смотри, что получится.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Крупные кнопки-заготовки: вставляют пример кода в редактор.
  Widget _examplesCard() {
    return _card(
      emoji: '✨',
      title: 'Примеры — нажми и запусти',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final example in _examples)
            ActionChip(
              avatar: const Text('▶', style: TextStyle(fontSize: 16)),
              label: Text(
                example.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              backgroundColor: const Color(0xFFEDF1FA),
              side: BorderSide(color: Colors.blueGrey.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onPressed: () {
                _controller.text = example.code;
                _focusNode.unfocus();
                setState(() => _result = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _card({String? emoji, String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (emoji != null) ...[
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Диалог с именем рисунка (по умолчанию «Рисунок 1»).
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.suggested});

  final String suggested;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggested);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Как назовём рисунок?',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        style: const TextStyle(fontSize: 18),
        decoration: const InputDecoration(
          hintText: 'Например: Квадрат',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        KidButton(
          label: 'Сохранить',
          emoji: '🖼',
          color: const Color(0xFF00B894),
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}
