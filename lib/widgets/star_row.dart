import 'package:flutter/material.dart';

/// Ряд из [total] звёзд, где [stars] закрашены.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.total = 3,
    this.size = 28,
  });

  final int stars;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? const Color(0xFFFDCB6E) : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}
