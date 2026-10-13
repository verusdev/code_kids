import 'dart:math';

import 'package:flutter/material.dart';

/// Простой «родительский замок»: несложный пример на сложение, чтобы младший
/// ребёнок случайно не попал в раздел для родителей.
Future<bool> showParentGate(BuildContext context) async {
  final passed = await showDialog<bool>(
    context: context,
    builder: (context) => const _ParentGateDialog(),
  );
  return passed ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  static const int _min = 3;
  static const int _max = 9;

  late final int _left;
  late final int _right;
  late final List<int> _options;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _left = _min + random.nextInt(_max - _min + 1);
    _right = _min + random.nextInt(_max - _min + 1);
    final answer = _left + _right;
    final options = <int>{answer};
    while (options.length < 3) {
      final candidate = answer + random.nextInt(7) - 3;
      if (candidate > 0) options.add(candidate);
    }
    _options = options.toList()..shuffle(random);
  }

  void _answer(int value) {
    if (value == _left + _right) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text(
              'Раздел для родителей',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Пожалуйста, решите пример:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Semantics(
              label: 'Сколько будет $_left плюс $_right?',
              excludeSemantics: true,
              child: Text(
                '$_left + $_right = ?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3776AB),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _options)
                  SizedBox(
                    width: 76,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _answer(option),
                      child: Text(
                        '$option',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_wrong) ...[
              const SizedBox(height: 12),
              const Text(
                'Попробуйте ещё раз 🙂',
                style: TextStyle(
                  color: Color(0xFFE84393),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}
