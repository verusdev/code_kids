import 'package:flutter/material.dart';

/// Описание простой команды-блока для конкретной игры
/// (например, «Вперёд» у робота или «Закрась» у пиксель-арта).
class BlockCommandDef {
  const BlockCommandDef({
    required this.id,
    required this.icon,
    required this.label,
    this.color,
  });

  /// Идентификатор команды внутри игры (executor сопоставляет его с действием).
  final String id;
  final IconData icon;
  final String label;

  /// Необязательный цвет команды — у команд выбора цвета в пиксель-арте
  /// иконка и подпись окрашиваются в соответствующий цвет.
  final Color? color;
}

/// Узел программы, собранной из блоков.
sealed class BlockNode {
  const BlockNode();
}

/// Простая команда.
class CommandBlock extends BlockNode {
  CommandBlock(this.def);

  final BlockCommandDef def;
}

/// Цикл «повторить N раз» — тело выполняется N раз.
class RepeatBlock extends BlockNode {
  RepeatBlock({this.times = 3, List<BlockNode>? body}) : body = body ?? [];

  int times;
  final List<BlockNode> body;
}

/// Условие «если …» — тело выполняется, только если условие истинно.
/// Точный смысл условия задаёт игра (у робота — «если впереди стена»).
class IfBlock extends BlockNode {
  IfBlock({List<BlockNode>? body}) : body = body ?? [];

  final List<BlockNode> body;
}

/// Определение «моей функции» — именованная последовательность простых
/// команд (аналог `def` в Python). Внутри только команды: циклы и условия
/// вкладывать нельзя, вложенность функций запрещена.
class FunctionDef {
  FunctionDef({required this.icon, List<BlockNode>? body})
      : body = body ?? [];

  /// Эмодзи-иконка функции (например, 🅰️).
  final String icon;

  /// Команды функции: от [kFunctionMinCommands] до [kFunctionMaxCommands].
  final List<BlockNode> body;
}

/// Вызов «моей функции» — при выполнении разворачивается в команды
/// определения. Вызывать можно несколько раз (не более [kFunctionMaxCalls]).
class FunctionCallBlock extends BlockNode {
  FunctionCallBlock(this.function);

  final FunctionDef function;
}

/// Ограничения конструктора программ (защита от «слишком больших» программ).
const int kBlockMaxNesting = 3;
const int kBlockMaxTotal = 40;
const int kBlockMaxSteps = 300;
const int kBlockMinTimes = 2;
const int kBlockMaxTimes = 6;

/// Ограничения «моей функции».
const int kFunctionMinCommands = 2;
const int kFunctionMaxCommands = 5;
const int kFunctionMaxCalls = 5;

/// Сколько всего блоков в списке (рекурсивно, вместе с вложенными).
/// Вызов функции считается одним блоком — его определение живёт отдельно.
int countBlocks(List<BlockNode> nodes) {
  var total = 0;
  for (final node in nodes) {
    total++;
    if (node is RepeatBlock) total += countBlocks(node.body);
    if (node is IfBlock) total += countBlocks(node.body);
  }
  return total;
}

/// Сколько вызовов [function] есть в списке (рекурсивно).
int countFunctionCalls(List<BlockNode> nodes, FunctionDef function) {
  var total = 0;
  for (final node in nodes) {
    if (node is FunctionCallBlock && node.function == function) total++;
    if (node is RepeatBlock) total += countFunctionCalls(node.body, function);
    if (node is IfBlock) total += countFunctionCalls(node.body, function);
  }
  return total;
}

/// Удаляет все вызовы [function] из списка (рекурсивно) —
/// нужно при удалении определения функции.
void removeFunctionCalls(List<BlockNode> nodes, FunctionDef function) {
  nodes.removeWhere((node) => node is FunctionCallBlock && node.function == function);
  for (final node in nodes) {
    if (node is RepeatBlock) removeFunctionCalls(node.body, function);
    if (node is IfBlock) removeFunctionCalls(node.body, function);
  }
}
