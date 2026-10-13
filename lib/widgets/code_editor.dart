import 'package:flutter/material.dart';

import 'code_widgets.dart';

/// Поле для ввода кода: моноширинный шрифт, тёмный фон, несколько строк.
class CodeEditor extends StatelessWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.minLines = 5,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        style: kMonoStyle,
        cursorColor: const Color(0xFF7FD1FF),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: '# пиши код здесь',
          hintStyle: TextStyle(
            color: Color(0xFF8B94A7),
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Панель быстрых кнопок: вставляют частые символы код в позицию курсора.
class QuickCodeBar extends StatelessWidget {
  const QuickCodeBar({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  static const List<_Insert> _items = [
    _Insert('print()', 'print()', 1),
    _Insert('input()', 'input()', 1),
    _Insert('"…"', '""', 1),
    _Insert("'…'", "''", 1),
    _Insert('[ ]', '[]', 1),
    _Insert('{ }', '{}', 1),
    _Insert('=', ' = '),
    _Insert(':', ':'),
    _Insert('+', ' + '),
    _Insert('-', ' - '),
    _Insert('*', ' * '),
    _Insert('/', ' / '),
    _Insert('⏎ отступ', '\n    '),
  ];

  void _insert(String text, int cursorBack) {
    final value = controller.value;
    final base = value.text;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : base.length;
    final end = selection.isValid ? selection.end : base.length;
    final newText = base.replaceRange(start, end, text);
    final cursor = start + text.length - cursorBack;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in _items)
          ActionChip(
            label: Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xFFEDF1FA),
            side: BorderSide(color: Colors.blueGrey.shade100),
            onPressed: () => _insert(item.text, item.cursorBack),
          ),
      ],
    );
  }
}

class _Insert {
  const _Insert(this.label, this.text, [this.cursorBack = 0]);

  final String label;
  final String text;
  final int cursorBack;
}
