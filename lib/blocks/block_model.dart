import 'package:flutter/material.dart';

/// Описание простой команды-блока для конкретной игры
/// (например, «Вперёд» у робота или «Закрась» у пиксель-арта).
class BlockCommandDef {
  const BlockCommandDef({
    required this.id,
    required this.icon,
    required this.label,
  });

  /// Идентификатор команды внутри игры (executor сопоставляет его с действием).
  final String id;
  final IconData icon;
  final String label;
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

/// Ограничения конструктора программ (защита от «слишком больших» программ).
const int kBlockMaxNesting = 3;
const int kBlockMaxTotal = 40;
const int kBlockMaxSteps = 300;
const int kBlockMinTimes = 2;
const int kBlockMaxTimes = 6;

/// Сколько всего блоков в списке (рекурсивно, вместе с вложенными).
int countBlocks(List<BlockNode> nodes) {
  var total = 0;
  for (final node in nodes) {
    total++;
    if (node is RepeatBlock) total += countBlocks(node.body);
    if (node is IfBlock) total += countBlocks(node.body);
  }
  return total;
}
