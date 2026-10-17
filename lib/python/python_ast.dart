// Узлы дерева разбора Python-подмножества.

abstract class Node {
  Node(this.line);

  final int line;
}

// ----- Операторы (statement) -----

class Program extends Node {
  Program(this.body) : super(0);

  final List<Node> body;
}

class AssignNode extends Node {
  AssignNode(this.name, this.value, int line) : super(line);

  final String name;
  final Node value;
}

class ExprStmt extends Node {
  ExprStmt(this.expr, int line) : super(line);

  final Node expr;
}

class IfNode extends Node {
  IfNode(this.condition, this.body, this.orelse, int line) : super(line);

  final Node condition;
  final List<Node> body;

  /// Ветка else/elif (elif сводится во вложенный IfNode).
  final List<Node> orelse;
}

class WhileNode extends Node {
  WhileNode(this.condition, this.body, int line) : super(line);

  final Node condition;
  final List<Node> body;
}

class ForNode extends Node {
  ForNode(this.variable, this.iterable, this.body, int line) : super(line);

  final String variable;
  final Node iterable;
  final List<Node> body;
}

class FuncDefNode extends Node {
  FuncDefNode(this.name, this.params, this.body, int line) : super(line);

  final String name;
  final List<String> params;
  final List<Node> body;
}

class ReturnNode extends Node {
  ReturnNode(this.value, int line) : super(line);

  final Node? value;
}

class BreakNode extends Node {
  BreakNode(super.line);
}

class ContinueNode extends Node {
  ContinueNode(super.line);
}

class PassNode extends Node {
  PassNode(super.line);
}

// ----- Новые операторы -----

/// Импорт модуля: `import random`
class ImportNode extends Node {
  ImportNode(this.module, int line) : super(line);

  final String module;
}

/// Обработка исключений: `try:` ... `except:` ...
class TryExceptNode extends Node {
  TryExceptNode(this.tryBody, this.exceptBody, this.exceptType, int line)
      : super(line);

  final List<Node> tryBody;
  final List<Node> exceptBody;
  final String? exceptType; // например 'NameError', 'ValueError' и т.д.
}

// ----- Выражения (expression) -----

class NumNode extends Node {
  NumNode(this.value, int line) : super(line);

  final num value;
}

class StrNode extends Node {
  StrNode(this.value, int line) : super(line);

  final String value;
}

class BoolNode extends Node {
  BoolNode(this.value, int line) : super(line);

  final bool value;
}

class NoneNode extends Node {
  NoneNode(super.line);
}

class NameNode extends Node {
  NameNode(this.name, int line) : super(line);

  final String name;
}

class BinOpNode extends Node {
  BinOpNode(this.op, this.left, this.right, int line) : super(line);

  final String op;
  final Node left;
  final Node right;
}

class UnaryOpNode extends Node {
  UnaryOpNode(this.op, this.operand, int line) : super(line);

  final String op;
  final Node operand;
}

class BoolOpNode extends Node {
  BoolOpNode(this.op, this.left, this.right, int line) : super(line);

  final String op; // and | or
  final Node left;
  final Node right;
}

class CompareNode extends Node {
  CompareNode(this.left, this.ops, this.comparators, int line) : super(line);

  final Node left;
  final List<String> ops;
  final List<Node> comparators;
}

class CallNode extends Node {
  CallNode(this.callee, this.args, int line) : super(line);

  final Node callee;
  final List<Node> args;
}

class ListNode extends Node {
  ListNode(this.elements, int line) : super(line);

  final List<Node> elements;
}

class IndexNode extends Node {
  IndexNode(this.target, this.index, int line) : super(line);

  final Node target;
  final Node index;
}

class AttributeNode extends Node {
  AttributeNode(this.target, this.name, int line) : super(line);

  final Node target;
  final String name;
}

/// Срез: `s[1:3]`, `s[:2]`, `s[2:]`, `s[::2]`. Любая граница может быть пустой.
class SliceNode extends Node {
  SliceNode(this.start, this.stop, this.step, int line) : super(line);

  final Node? start;
  final Node? stop;
  final Node? step;
}

/// Литерал словаря: `{'кот': 3, 'пёс': 5}`.
class DictNode extends Node {
  DictNode(this.keys, this.values, int line) : super(line);

  final List<Node> keys;
  final List<Node> values;
}

/// Присваивание по индексу: `список[0] = 5` или `словарь['ключ'] = 1`.
class AssignIndexNode extends Node {
  AssignIndexNode(this.target, this.index, this.value, int line) : super(line);

  final Node target;
  final Node index;
  final Node value;
}
