// Проверка инварианта уровней игры «Части и целое».
//
// Для каждого уровня игры должно выполняться:
//   options[correctIndex] == parts[missingIndex]
// то есть «верный» вариант в точности совпадает с пропавшей частью.
// Дополнительно: варианты уникальны и пропавшая часть присутствует среди них.
//
// Скрипт читает исходник lib/games/parts/parts_game.dart как текст и разбирает
// литералы уровней — поэтому запускается обычным `dart run` без Flutter.
//
// Запуск: dart run tool/parts_check.dart
import 'dart:io';

class _Part {
  const _Part(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _Level {
  const _Level({
    required this.index,
    required this.title,
    required this.parts,
    required this.missingIndex,
    required this.options,
    required this.correctIndex,
  });

  final int index;
  final String title;
  final List<_Part> parts;
  final int missingIndex;
  final List<_Part> options;
  final int correctIndex;
}

void main() {
  final file = _findSource();
  if (file == null) {
    stderr.writeln('Не найден lib/games/parts/parts_game.dart');
    exit(2);
  }

  final src = file.readAsStringSync();
  final region = _extractList(src, 'final List<PartsLevel> _partsLevels = [');
  if (region == null) {
    stderr.writeln('Не найден список уровней _partsLevels.');
    exit(2);
  }

  final levels = <_Level>[];
  var from = 0;
  while (true) {
    final start = region.indexOf('const PartsLevel(', from);
    if (start < 0) break;
    final open = region.indexOf('(', start);
    final close = _matchPair(region, open, '(', ')');
    levels.add(_parseLevel(region.substring(open + 1, close), levels.length + 1));
    from = close + 1;
  }

  if (levels.isEmpty) {
    stderr.writeln('Не удалось разобрать ни одного уровня.');
    exit(2);
  }

  var failures = 0;
  for (final level in levels) {
    if (level.missingIndex < 0 || level.missingIndex >= level.parts.length) {
      failures++;
      stdout.writeln('FAIL ${_n(level.index)}. ${level.title} — missingIndex вне границ');
      continue;
    }
    if (level.correctIndex < 0 || level.correctIndex >= level.options.length) {
      failures++;
      stdout.writeln('FAIL ${_n(level.index)}. ${level.title} — correctIndex вне границ');
      continue;
    }

    final missing = level.parts[level.missingIndex];
    final correct = level.options[level.correctIndex];
    final sameEmoji = missing.emoji == correct.emoji;
    final sameLabel = missing.label == correct.label;
    final unique = level.options
            .map((p) => '${p.emoji}|${p.label}')
            .toSet()
            .length ==
        level.options.length;
    final present = level.options
        .any((p) => p.emoji == missing.emoji && p.label == missing.label);

    if (sameEmoji && sameLabel && unique && present) {
      stdout.writeln('OK   ${_n(level.index)}. ${level.title}');
    } else {
      failures++;
      stdout.writeln('FAIL ${_n(level.index)}. ${level.title}');
      stdout.writeln('     пропало  parts[${level.missingIndex}] = '
          '${missing.emoji} ${missing.label}');
      stdout.writeln('     верный   options[${level.correctIndex}] = '
          '${correct.emoji} ${correct.label}');
      if (!unique) stdout.writeln('     варианты не уникальны');
      if (!present) stdout.writeln('     пропавшей части нет среди вариантов');
    }
  }

  stdout.writeln('');
  stdout.writeln('Проверено уровней: ${levels.length}, ошибок: $failures');
  if (levels.length != 30) {
    stdout.writeln('ВНИМАНИЕ: ожидалось 30 уровней.');
  }
  exit(failures == 0 ? 0 : 1);
}

String _n(int i) => i.toString().padLeft(2, '0');

File? _findSource() {
  final candidates = [
    File('lib/games/parts/parts_game.dart'),
    File.fromUri(Platform.script.resolve('../lib/games/parts/parts_game.dart')),
  ];
  for (final f in candidates) {
    if (f.existsSync()) return f;
  }
  return null;
}

/// Возвращает содержимое внутри `[...]` после маркера [marker] (без скобок).
String? _extractList(String src, String marker) {
  final markerIndex = src.indexOf(marker);
  if (markerIndex < 0) return null;
  final open = src.indexOf('[', markerIndex);
  if (open < 0) return null;
  final close = _matchPair(src, open, '[', ']');
  if (close < 0) return null;
  return src.substring(open + 1, close);
}

/// Индекс закрывающей скобки с учётом вложенности и строк в одинарных кавычках.
int _matchPair(String s, int openIndex, String open, String close) {
  var depth = 0;
  var inString = false;
  for (var i = openIndex; i < s.length; i++) {
    final c = s[i];
    if (inString) {
      if (c == r'\') {
        i++;
      } else if (c == "'") {
        inString = false;
      }
      continue;
    }
    if (c == "'") {
      inString = true;
    } else if (c == open) {
      depth++;
    } else if (c == close) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

_Level _parseLevel(String block, int index) {
  final title = _firstString(block, RegExp(r"title:\s*'([^']*)'"));
  final missingIndex = _firstInt(block, RegExp(r'missingIndex:\s*(\d+)'));
  final correctIndex = _firstInt(block, RegExp(r'correctIndex:\s*(\d+)'));
  return _Level(
    index: index,
    title: title,
    parts: _parts(block, 'parts'),
    missingIndex: missingIndex,
    options: _parts(block, 'options'),
    correctIndex: correctIndex,
  );
}

List<_Part> _parts(String block, String field) {
  final fieldIndex = block.indexOf('$field:');
  if (fieldIndex < 0) return const [];
  final open = block.indexOf('[', fieldIndex);
  if (open < 0) return const [];
  final close = _matchPair(block, open, '[', ']');
  if (close < 0) return const [];
  final body = block.substring(open + 1, close);
  return RegExp(r"PartItem\(\s*'([^']*)'\s*,\s*'([^']*)'\s*\)")
      .allMatches(body)
      .map((m) => _Part(m.group(1)!, m.group(2)!))
      .toList(growable: false);
}

String _firstString(String s, RegExp re) {
  final m = re.firstMatch(s);
  return m?.group(1) ?? '';
}

int _firstInt(String s, RegExp re) {
  final m = re.firstMatch(s);
  return m == null ? -1 : int.parse(m.group(1)!);
}
