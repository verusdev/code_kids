import 'package:flutter/material.dart';

import '../services/sound_service.dart';

/// Крупная «детская» кнопка с эмодзи и подписью.
class KidButton extends StatelessWidget {
  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emoji,
    this.icon,
    this.color,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? emoji;
  final IconData? icon;
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bg = onPressed == null
        ? Colors.grey.shade300
        : (color ?? Theme.of(context).colorScheme.primary);

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );

    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              SoundService.tap();
              onPressed!();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        elevation: onPressed == null ? 0 : 4,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: child,
    );
  }
}
