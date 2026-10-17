import 'python_ast.dart';
import 'python_error.dart';
import 'python_lexer.dart';

/// Парсер: токены → дерево (AST). Классический рекурсивный спуск.
class PythonParser {
  PythonParser(this.tokens);

  final List<Token> tokens;
  int _pos = 0;

  Token get _cur => tokens[_pos];

  bool _check(TokType type, [String? text]) =>
      _cur.type == type && (text == null || _cur.text == text);

  Token _advance() => tokens[_pos++];

  Token _expect(TokType type, String what) {
    if (_cur.type != type) {
      throw PythonError('Ожидалось $what, а найдено «${_cur.text}»',
          line: _cur.line);
    }
    return _advance();
  }

  bool _matchKeyword(String kw) {
    if (_cur.type == TokType.keyword && _cur.text == kw) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchOp(String op) {
    if (_cur.type == TokType.op && _cur.text == op) {
      _advance();
      return true;
    }
    return false;
  }

  Program parse() {
    final body = <Node>[];
    _skipNewlines();
    while (!_check(TokType.eof)) {
      body.add(_statement());
      _skipNewlines();
    }
    return Program(body);
  }

  void _skipNewlines() {
    while (_check(TokType.newline)) {
      _advance();
    }
  }

  Node _statement() {
    if (_cur.type == TokType.keyword) {
      switch (_cur.text) {
        case 'if':
          return _ifStatement();
        case 'while':
          return _whileStatement();
        case 'for':
          return _forStatement();
        case 'def':
          return _funcDef();
        case 'try':
          return _tryStatement();
        case 'import':
          return _importStatement();
      }
    }
    return _simpleStatement();
  }

  Node _simpleStatement() {
    final line = _cur.line;
    if (_matchKeyword('return')) {
      if (_check(TokType.newline) || _check(TokType.eof)) {
        return ReturnNode(null, line);
      }
      return ReturnNode(_expression(), line);
    }
    if (_matchKeyword('break')) return BreakNode(line);
    if (_matchKeyword('continue')) return ContinueNode(line);
    if (_matchKeyword('pass')) return PassNode(line);

    // Присваивание: NAME '=' expr
    if (_cur.type == TokType.name &&
        _pos + 1 < tokens.length &&
        tokens[_pos + 1].type == TokType.op &&
        tokens[_pos + 1].text == '=') {
      final name = _advance().text;
      _advance(); // =
      return AssignNode(name, _expression(), line);
    }

    // Присваивание по индексу: список[0] = ..., словарь['ключ'] = ...
    if (_looksLikeSubscriptAssign()) {
      final target = _postfix();
      _matchOp('=');
      if (target is IndexNode) {
        return AssignIndexNode(
          target.target,
          target.index,
          _expression(),
          line,
        );
      }
    }
    return ExprStmt(_expression(), line);
  }

  /// Проверяет «на глаз», начинается ли выражение с `имя[...]...[` и кончается `=`.
  /// Нужно, чтобы отличить присваивание по индексу от обычного выражения.
  bool _looksLikeSubscriptAssign() {
    if (_cur.type != TokType.name) return false;
    int i = _pos + 1;
    bool sawSubscript = false;
    while (i < tokens.length &&
        tokens[i].type == TokType.op &&
        tokens[i].text == '[') {
      int depth = 0;
      while (i < tokens.length) {
        final t = tokens[i];
        if (t.type == TokType.op && t.text == '[') {
          depth++;
          i++;
        } else if (t.type == TokType.op && t.text == ']') {
          depth--;
          i++;
          if (depth == 0) break;
        } else {
          i++;
        }
      }
      sawSubscript = true;
    }
    if (!sawSubscript) return false;
    return i < tokens.length &&
        tokens[i].type == TokType.op &&
        tokens[i].text == '=';
  }

  List<Node> _block() {
    _expect(TokType.newline, 'конец строки');
    _expect(TokType.indent, 'отступ (4 пробела) для блока');
    final body = <Node>[];
    _skipNewlines();
    while (!_check(TokType.dedent) && !_check(TokType.eof)) {
      body.add(_statement());
      _skipNewlines();
    }
    if (_check(TokType.dedent)) _advance();
    if (body.isEmpty) {
      throw PythonError('После «:» нужен хотя бы один шаг с отступом',
          line: _cur.line);
    }
    return body;
  }

  Node _ifStatement() {
    final line = _cur.line;
    _advance(); // if
    final condition = _expression();
    _expectOp(':');
    final body = _block();
    final orelse = _elsePart();
    return IfNode(condition, body, orelse, line);
  }

  /// Разбирает `elif`/`else` после блока `if`, рекурсивно.
  List<Node> _elsePart() {
    if (_matchKeyword('elif')) {
      final line = tokens[_pos - 1].line;
      final condition = _expression();
      _expectOp(':');
      final body = _block();
      final orelse = _elsePart();
      return <Node>[IfNode(condition, body, orelse, line)];
    }
    if (_matchKeyword('else')) {
      _expectOp(':');
      return _block();
    }
    return <Node>[];
  }

  void _expectOp(String op) {
    if (!_check(TokType.op, op)) {
      throw PythonError('Ожидалось «$op»', line: _cur.line);
    }
    _advance();
  }

  Node _whileStatement() {
    final line = _advance().line; // while
    final condition = _expression();
    _expectOp(':');
    final body = _block();
    return WhileNode(condition, body, line);
  }

  Node _forStatement() {
    final line = _advance().line; // for
    final variable = _expect(TokType.name, 'имя переменной').text;
    if (!_matchKeyword('in')) {
      throw PythonError('Ожидалось «in»', line: _cur.line);
    }
    final iterable = _expression();
    _expectOp(':');
    final body = _block();
    return ForNode(variable, iterable, body, line);
  }

  Node _funcDef() {
    final line = _advance().line; // def
    final name = _expect(TokType.name, 'имя функции').text;
    _expectOp('(');
    final params = <String>[];
    if (!_check(TokType.op, ')')) {
      params.add(_expect(TokType.name, 'параметр').text);
      while (_matchOp(',')) {
        params.add(_expect(TokType.name, 'параметр').text);
      }
    }
    _expectOp(')');
    _expectOp(':');
    final body = _block();
    return FuncDefNode(name, params, body, line);
  }

  Node _tryStatement() {
    final line = _advance().line; // try
    _expectOp(':');
    final tryBody = _block();
    if (!_check(TokType.keyword, 'except')) {
      throw PythonError('Ожидалось «except»', line: _cur.line);
    }
    _advance(); // except
    String? exceptType;
    if (_cur.type == TokType.name) {
      exceptType = _cur.text;
      _advance();
    }
    _expectOp(':');
    final exceptBody = _block();
    return TryExceptNode(tryBody, exceptBody, exceptType, line);
  }

  /// Разбирает `import имя_модуля`.
  Node _importStatement() {
    final line = _advance().line; // import
    final module = _expect(TokType.name, 'имя модуля').text;
    return ImportNode(module, line);
  }

  // ----- выражения -----

  Node _expression() => _orExpr();

  Node _orExpr() {
    var left = _andExpr();
    while (_matchKeyword('or')) {
      final line = tokens[_pos - 1].line;
      left = BoolOpNode('or', left, _andExpr(), line);
    }
    return left;
  }

  Node _andExpr() {
    var left = _notExpr();
    while (_matchKeyword('and')) {
      final line = tokens[_pos - 1].line;
      left = BoolOpNode('and', left, _notExpr(), line);
    }
    return left;
  }

  Node _notExpr() {
    if (_matchKeyword('not')) {
      final line = tokens[_pos - 1].line;
      return UnaryOpNode('not', _notExpr(), line);
    }
    return _comparison();
  }

  static const List<String> _compareOps = ['==', '!=', '<=', '>=', '<', '>'];

  Node _comparison() {
    var left = _additive();
    final ops = <String>[];
    final comparators = <Node>[];
    while (true) {
      if (_cur.type == TokType.op && _compareOps.contains(_cur.text)) {
        ops.add(_advance().text);
        comparators.add(_additive());
      } else if (_cur.type == TokType.keyword && _cur.text == 'in') {
        _advance();
        ops.add('in');
        comparators.add(_additive());
      } else if (_cur.type == TokType.keyword &&
          _cur.text == 'not' &&
          _pos + 1 < tokens.length &&
          tokens[_pos + 1].type == TokType.keyword &&
          tokens[_pos + 1].text == 'in') {
        _advance(); // not
        _advance(); // in
        ops.add('not in');
        comparators.add(_additive());
      } else {
        break;
      }
    }
    if (ops.isEmpty) return left;
    return CompareNode(left, ops, comparators, left.line);
  }

  Node _additive() {
    var left = _term();
    while (_cur.type == TokType.op && (_cur.text == '+' || _cur.text == '-')) {
      final op = _advance().text;
      left = BinOpNode(op, left, _term(), left.line);
    }
    return left;
  }

  Node _term() {
    var left = _factor();
    while (_cur.type == TokType.op &&
        (_cur.text == '*' || _cur.text == '/' || _cur.text == '//' || _cur.text == '%')) {
      final op = _advance().text;
      left = BinOpNode(op, left, _factor(), left.line);
    }
    return left;
  }

  Node _factor() {
    if (_cur.type == TokType.op && (_cur.text == '-' || _cur.text == '+')) {
      final op = _advance().text;
      return UnaryOpNode(op, _factor(), _cur.line);
    }
    return _power();
  }

  Node _power() {
    final base = _postfix();
    if (_matchOp('**')) {
      return BinOpNode('**', base, _factor(), base.line);
    }
    return base;
  }

  Node _postfix() {
    var expr = _atom();
    while (true) {
      if (_check(TokType.op, '(')) {
        _advance();
        final args = <Node>[];
        if (!_check(TokType.op, ')')) {
          args.add(_expression());
          while (_matchOp(',')) {
            args.add(_expression());
          }
        }
        _expectOp(')');
        expr = CallNode(expr, args, expr.line);
      } else if (_check(TokType.op, '[')) {
        _advance();
        final index = _subscriptContent(expr.line);
        expr = IndexNode(expr, index, expr.line);
      } else if (_check(TokType.op, '.')) {
        _advance();
        final name = _expect(TokType.name, 'имя метода').text;
        expr = AttributeNode(expr, name, expr.line);
      } else {
        break;
      }
    }
    return expr;
  }

  /// Разбирает содержимое квадратных скобок: обычный индекс или срез.
  /// Открывающая `[` уже прочитана; закрывающую `]` читаем здесь.
  Node _subscriptContent(int line) {
    Node? start;
    if (!_check(TokType.op, ':')) {
      start = _expression();
    }
    if (_matchOp(':')) {
      Node? stop;
      if (!_check(TokType.op, ':') && !_check(TokType.op, ']')) {
        stop = _expression();
      }
      Node? step;
      if (_matchOp(':')) {
        if (!_check(TokType.op, ']')) {
          step = _expression();
        }
      }
      _expectOp(']');
      return SliceNode(start, stop, step, line);
    }
    _expectOp(']');
    return start!;
  }

  Node _atom() {
    final t = _cur;
    if (t.type == TokType.num) {
      _advance();
      return NumNode(t.value as num, t.line);
    }
    if (t.type == TokType.str) {
      _advance();
      return StrNode(t.value as String, t.line);
    }
    if (t.type == TokType.keyword) {
      if (t.text == 'True') {
        _advance();
        return BoolNode(true, t.line);
      }
      if (t.text == 'False') {
        _advance();
        return BoolNode(false, t.line);
      }
      if (t.text == 'None') {
        _advance();
        return NoneNode(t.line);
      }
    }
    if (t.type == TokType.name) {
      _advance();
      return NameNode(t.text, t.line);
    }
    if (_check(TokType.op, '(')) {
      _advance();
      final e = _expression();
      _expectOp(')');
      return e;
    }
    if (_check(TokType.op, '[')) {
      _advance();
      final elements = <Node>[];
      if (!_check(TokType.op, ']')) {
        elements.add(_expression());
        while (_matchOp(',')) {
          if (_check(TokType.op, ']')) break;
          elements.add(_expression());
        }
      }
      _expectOp(']');
      return ListNode(elements, t.line);
    }
    if (_check(TokType.op, '{')) {
      _advance();
      final keys = <Node>[];
      final values = <Node>[];
      if (!_check(TokType.op, '}')) {
        keys.add(_expression());
        _expectOp(':');
        values.add(_expression());
        while (_matchOp(',')) {
          if (_check(TokType.op, '}')) break;
          keys.add(_expression());
          _expectOp(':');
          values.add(_expression());
        }
      }
      _expectOp('}');
      return DictNode(keys, values, t.line);
    }
    throw PythonError('Непонятное выражение около «${t.text}»', line: t.line);
  }
}
