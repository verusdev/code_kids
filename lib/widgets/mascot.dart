import 'package:flutter/material.dart';

import '../services/mascot_service.dart';

/// Круглый аватар маскота с надетыми аксессуарами.
///
/// Базовый эмодзи рисуется в центре круга, а надетые в магазине наряды —
/// маленькими эмодзи по краям: шляпа сверху, очки и детали снизу.
/// Виджет подписан на [MascotService], поэтому наряд обновляется сразу
/// после покупки. Без надетых аксессуаров выглядит как обычный круг.
class MascotAvatar extends StatelessWidget {
  const MascotAvatar({
    super.key,
    this.emoji = '🐱',
    this.color = const Color(0xFFFFE066),
    this.size = 58,
    this.showAccessories = true,
  });

  /// Базовый эмодзи маскота.
  final String emoji;

  /// Цвет круга.
  final Color color;

  /// Размер круга (аксессуары масштабируются вместе с ним).
  final double size;

  /// Показывать ли надетые аксессуары (по умолчанию — да).
  final bool showAccessories;

  @override
  Widget build(BuildContext context) {
    final shop = MascotService.instance;
    return ListenableBuilder(
      listenable: shop,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: size * 3 / 58),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: TextStyle(fontSize: size * 30 / 58)),
              ),
              if (showAccessories) ...[
                _accessory(
                  shop.emojiForSlot(AccessorySlot.hat),
                  Alignment.topCenter,
                  Offset(0, -size * 9 / 58),
                ),
                _accessory(
                  shop.emojiForSlot(AccessorySlot.face),
                  Alignment.bottomRight,
                  Offset(size * 9 / 58, size * 5 / 58),
                ),
                _accessory(
                  shop.emojiForSlot(AccessorySlot.extra),
                  Alignment.bottomLeft,
                  Offset(-size * 9 / 58, size * 5 / 58),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Маленький «бейдж» с эмодзи аксессуара, появляющийся с лёгкой анимацией.
  Widget _accessory(String? accessoryEmoji, Alignment alignment, Offset offset) {
    if (accessoryEmoji == null) return const SizedBox.shrink();
    final badge = size * 22 / 58;
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: badge,
            height: badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              accessoryEmoji,
              style: TextStyle(fontSize: badge * 12 / 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Персонаж-гид с репликой в «облачке».
///
/// По умолчанию рисует надетые в магазине аксессуары (см. [MascotAvatar]);
/// их можно отключить параметром [showAccessories].
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.message,
    this.emoji = '🐱',
    this.color = const Color(0xFFFFE066),
    this.showAccessories = true,
  });

  final String message;
  final String emoji;
  final Color color;

  /// Показывать ли надетые аксессуары (по умолчанию — да).
  final bool showAccessories;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotAvatar(
          emoji: emoji,
          color: color,
          showAccessories: showAccessories,
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
