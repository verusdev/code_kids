import 'package:flutter/material.dart';

import '../python/python_runner.dart';

/// Моноширинный стиль для кода и вывода.
const TextStyle kMonoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Consolas', 'Courier New', 'monospace'],
  fontSize: 16,
  height: 1.5,
  color: Color(0xFFE6EDF3),
);

/// Блок кода только для чтения (пример в уроке).
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.label});

  final String code;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(code, style: kMonoStyle),
        ),
      ],
    );
  }
}

/// Консоль — куда программа печатает результат.
class CodeConsole extends StatelessWidget {
  const CodeConsole({
    super.key,
    this.result,
    this.placeholder = 'Здесь появится результат…',
  });

  final PythonResult? result;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final children = <Widget>[];

    if (r == null) {
      children.add(Text(
        placeholder,
        style: kMonoStyle.copyWith(
          color: const Color(0xFF8B94A7),
          fontStyle: FontStyle.italic,
        ),
      ));
    } else {
      for (final line in r.output) {
        children.add(Text(line.isEmpty ? ' ' : line, style: kMonoStyle));
      }
      if (r.error != null) {
        if (r.output.isNotEmpty) {
          children.add(const SizedBox(height: 6));
        }
        children.add(Text(
          '⚠️ ${r.error}',
          style: kMonoStyle.copyWith(color: const Color(0xFFFF8A80)),
        ));
      } else if (r.output.isEmpty) {
        children.add(Text(
          '(программа ничего не напечатала)',
          style: kMonoStyle.copyWith(color: const Color(0xFF8B94A7)),
        ));
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12151C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r != null && r.error != null
              ? const Color(0xFFFF8A80)
              : const Color(0xFF2A2F3A),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
