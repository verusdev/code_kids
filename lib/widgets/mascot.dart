import 'package:flutter/material.dart';

/// Персонаж-гид с репликой в «облачке».
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.message,
    this.emoji = '🐱',
    this.color = const Color(0xFFFFE066),
  });

  final String message;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
