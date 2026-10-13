import 'package:flutter/material.dart';

import '../blocks/block_model.dart';
import '../theme/app_theme.dart';

/// Конструктор программы из блоков.
///
/// Программа — это список блоков. Здесь можно добавлять простые команды,
/// вкладывать их в цикл «повторить N раз» и в условие «если …».
/// Списки (в т.ч. тела циклов) редактируются прямо на месте.
class BlockEditor extends StatelessWidget {
  const BlockEditor({
    super.key,
    required this.nodes,
    required this.commands,
    required this.onChanged,
    this.conditionLabel,
    this.enabled = true,
    this.depth = 0,
  });

  /// Редактируемый список блоков.
  final List<BlockNode> nodes;

  /// Доступные простые команды.
  final List<BlockCommandDef> commands;

  /// Вызывается после любого изменения — чтобы родитель перестроил UI.
  final VoidCallback onChanged;

  /// Подпись условия для блока «если …»; null — условие недоступно.
  final String? conditionLabel;

  final bool enabled;

  /// Текущая глубина вложенности (0 — верхний уровень программы).
  final int depth;

  bool get _canAddContainer =>
      enabled && depth + 1 < kBlockMaxNesting;

  bool get _hasRoom => countBlocks(nodes) < kBlockMaxTotal;

  void _add(BlockNode node) {
    if (!_hasRoom) return;
    nodes.add(node);
    onChanged();
  }

  void _removeAt(int index) {
    nodes.removeAt(index);
    onChanged();
  }

  void _changeTimes(RepeatBlock block, int delta) {
    final next = (block.times + delta).clamp(kBlockMinTimes, kBlockMaxTimes);
    if (next == block.times) return;
    block.times = next;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nodes.isEmpty && !enabled)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('— пусто —', style: TextStyle(color: Colors.grey)),
          ),
        for (var i = 0; i < nodes.length; i++) _node(nodes[i], i),
        if (enabled) _addBar(),
      ],
    );
  }

  Widget _node(BlockNode node, int index) {
    return switch (node) {
      CommandBlock() => _commandRow(node, index),
      RepeatBlock() => _container(
          node,
          index,
          title: '🔁 Повторить',
          color: AppTheme.orange,
          trailing: _timesControl(node),
        ),
      IfBlock() => _container(
          node,
          index,
          title: '🧱 ${conditionLabel ?? 'Если'}',
          color: AppTheme.sky,
        ),
    };
  }

  Widget _commandRow(CommandBlock node, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.purple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(node.def.icon, size: 20, color: AppTheme.purple),
                const SizedBox(width: 6),
                Text(
                  node.def.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (enabled)
            IconButton(
              onPressed: () => _removeAt(index),
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey,
              tooltip: 'Убрать блок',
            ),
        ],
      ),
    );
  }

  Widget _timesControl(RepeatBlock block) {
    if (!enabled) {
      return Text(
        '${block.times} раз',
        style: const TextStyle(fontWeight: FontWeight.w800),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundButton(
          icon: Icons.remove_rounded,
          onTap: () => _changeTimes(block, -1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${block.times}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        _roundButton(
          icon: Icons.add_rounded,
          onTap: () => _changeTimes(block, 1),
        ),
        const SizedBox(width: 6),
        const Text('раз', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _container(
    BlockNode node,
    int index, {
    required String title,
    required Color color,
    Widget? trailing,
  }) {
    final body = node is RepeatBlock ? node.body : (node as IfBlock).body;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
              if (enabled)
                IconButton(
                  onPressed: () => _removeAt(index),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.grey,
                  tooltip: 'Убрать блок',
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: BlockEditor(
              nodes: body,
              commands: commands,
              onChanged: onChanged,
              conditionLabel: conditionLabel,
              enabled: enabled && depth + 1 < kBlockMaxNesting,
              depth: depth + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addBar() {
    final canAdd = enabled && _hasRoom;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final command in commands)
          _miniButton(
            label: command.label,
            icon: command.icon,
            color: AppTheme.purple,
            onTap: canAdd ? () => _add(CommandBlock(command)) : null,
          ),
        if (_canAddContainer)
          _miniButton(
            label: 'Повторить',
            icon: Icons.repeat_rounded,
            color: AppTheme.orange,
            onTap: canAdd ? () => _add(RepeatBlock()) : null,
          ),
        if (_canAddContainer && conditionLabel != null)
          _miniButton(
            label: conditionLabel!,
            icon: Icons.rule_rounded,
            color: AppTheme.sky,
            onTap: canAdd ? () => _add(IfBlock()) : null,
          ),
      ],
    );
  }

  Widget _miniButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: onTap == null ? Colors.grey.shade200 : color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: onTap == null ? Colors.grey : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? Colors.grey : AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.purple.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppTheme.purple),
        ),
      ),
    );
  }
}
