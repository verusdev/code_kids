import 'python_error.dart';

/// Типы токенов Python-подмножества.
enum TokType { num, str, name, keyword, op, newline, indent, dedent, eof }

/// Токен с позицией (номер строки — для понятных ошибок).
class Token {
  Token(this.type, this.text, this.line, [this.value]);

  final TokType type;
  final String text;
  final int line;
  final Object? value;

  @override
  String toString() => '${type.name}($text)@$line';
}

/// Лексер: превращает исходник в поток токенов, добавляя NEWLINE,
/// INDENT и DEDENT — как в настоящем Python, где блоки задаются отступами.
class PythonLexer {
  static const Set<String> keywords = {
    'and', 'or', 'not', 'if', 'elif', 'else', 'while', 'for', 'in', 'def',
    'return', 'True', 'False', 'None', 'break', 'continue', 'pass',
    'import', 'try', 'except',
  };

  static const List<String> _twoCharOps = [
    '//', '**', '==', '!=', '<=', '>=',
  ];

  static const String _oneCharOps = '+-*/%<>=()[]{},:.';

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  bool _isLetter(String ch) => _letter.hasMatch(ch);

  bool _isDigit(String ch) => _digit.hasMatch(ch);

  bool _isIdentStart(String ch) => ch == '_' || _isLetter(ch);

  bool _isIdentPart(String ch) => ch == '_' || _isLetter(ch) || _isDigit(ch);

  List<Token> tokenize(String source) {
    final tokens = <Token>[];
    final lines = source
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final indents = <int>[0];

    for (int i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final stripped = _stripComment(lines[i]);
      if (stripped.trim().isEmpty) continue;

      int indent = 0;
      int p = 0;
      while (p < stripped.length) {
        final c = stripped[p];
        if (c == ' ') {
          indent++;
          p++;
        } else if (c == '\t') {
          indent += 4;
          p++;
        } else {
          break;
        }
      }
      final content = stripped.substring(p).trimRight();
      if (content.isEmpty) continue;

      if (indent > indents.last) {
        indents.add(indent);
        tokens.add(Token(TokType.indent, '<indent>', lineNo));
      } else {
        while (indent < indents.last) {
          indents.removeLast();
          tokens.add(Token(TokType.dedent, '<dedent>', lineNo));
        }
        if (indent != indents.last) {
          throw PythonError(
            'Неверный отступ. Проверь, сколько пробелов в начале строки.',
            line: lineNo,
          );
        }
      }

      tokens.addAll(_tokenizeLine(content, lineNo));
      tokens.add(Token(TokType.newline, '<newline>', lineNo));
    }

    while (indents.length > 1) {
      indents.removeLast();
      tokens.add(Token(TokType.dedent, '<dedent>', lines.length));
    }
    tokens.add(Token(TokType.eof, '<eof>', lines.length));
    return tokens;
  }

  /// Убирает комментарий, начиная с `#`, не задевая символы внутри строк.
  String _stripComment(String line) {
    String? quote;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (quote != null) {
        if (c == '\\') {
          i++;
        } else if (c == quote) {
          quote = null;
        }
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == '#') {
        return line.substring(0, i);
      }
    }
    return line;
  }

  List<Token> _tokenizeLine(String s, int lineNo) {
    final out = <Token>[];
    int i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == ' ' || c == '\t') {
        i++;
        continue;
      }
      if (_isDigit(c)) {
        final start = i;
        while (i < s.length && _isDigit(s[i])) {
          i++;
        }
        bool isDouble = false;
        if (i < s.length && s[i] == '.' && i + 1 < s.length && _isDigit(s[i + 1])) {
          isDouble = true;
          i++;
          while (i < s.length && _isDigit(s[i])) {
            i++;
          }
        }
        final text = s.substring(start, i);
        out.add(Token(
          TokType.num,
          text,
          lineNo,
          isDouble ? double.parse(text) : int.parse(text),
        ));
        continue;
      }
      if (_isIdentStart(c)) {
        final start = i;
        while (i < s.length && _isIdentPart(s[i])) {
          i++;
        }
        final text = s.substring(start, i);
        out.add(Token(
          keywords.contains(text) ? TokType.keyword : TokType.name,
          text,
          lineNo,
        ));
        continue;
      }
      if (c == '"' || c == "'") {
        out.add(_readString(s, i, c, lineNo));
        i = _lastStringEnd;
        continue;
      }
      final two = i + 1 < s.length ? s.substring(i, i + 2) : '';
      if (_twoCharOps.contains(two)) {
        out.add(Token(TokType.op, two, lineNo));
        i += 2;
        continue;
      }
      if (_oneCharOps.contains(c)) {
        out.add(Token(TokType.op, c, lineNo));
        i++;
        continue;
      }
      throw PythonError('Непонятный символ «$c»', line: lineNo);
    }
    return out;
  }

  int _lastStringEnd = 0;

  Token _readString(String s, int start, String quote, int lineNo) {
    final buffer = StringBuffer();
    int i = start + 1;
    while (i < s.length) {
      final c = s[i];
      if (c == '\\' && i + 1 < s.length) {
        final n = s[i + 1];
        switch (n) {
          case 'n':
            buffer.write('\n');
          case 't':
            buffer.write('\t');
          case '\\':
            buffer.write('\\');
          case "'":
            buffer.write("'");
          case '"':
            buffer.write('"');
          default:
            buffer.write(n);
        }
        i += 2;
        continue;
      }
      if (c == quote) {
        _lastStringEnd = i + 1;
        return Token(TokType.str, s.substring(start, i + 1), lineNo, buffer.toString());
      }
      buffer.write(c);
      i++;
    }
    throw PythonError('Незакрытая кавычка', line: lineNo);
  }
}
