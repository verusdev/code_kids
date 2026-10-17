import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/mascot_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot.dart';

/// Экран «🛒 Наряды» — магазин аксессуаров для кота Байта.
///
/// Сверху видно, как кот выглядит в текущем наряде и сколько у тебя звёзд,
/// ниже — сетка аксессуаров. Купленные можно надеть или снять, новые —
/// купить за звёзды. Если звёзд не хватает — мягкая подсказка без наказаний.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = MascotService.instance;
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('🛒 Наряды')),
      body: ListenableBuilder(
        listenable: Listenable.merge([shop, progress]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Preview(stars: shop.stars),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: kAccessories.length,
                itemBuilder: (context, index) {
                  final accessory = kAccessories[index];
                  return _AccessoryCard(
                    accessory: accessory,
                    owned: shop.isOwned(accessory.id),
                    equipped: shop.isEquipped(accessory),
                    canAfford: shop.stars >= accessory.price,
                    onTap: () => _onTap(context, accessory),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onTap(BuildContext context, Accessory accessory) async {
    final shop = MascotService.instance;
    final messenger = ScaffoldMessenger.of(context);
    if (shop.isOwned(accessory.id)) {
      // Надеть или снять уже купленный наряд.
      await SoundService.tap();
      await HapticFeedback.selectionClick();
      await shop.toggle(accessory);
      return;
    }
    final bought = await shop.buy(accessory);
    if (bought) {
      // Победный сигнал сервиса уже включает вибро-отклик.
      await SoundService.win();
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {
        // На платформах без канала HapticFeedback вызов может зависнуть или
        // упасть — не даём этому помешать показу подсказки.
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Ура! Наряд «${accessory.name}» открыт! ${accessory.emoji}')),
      );
    } else {
      await SoundService.wrong();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Собери ещё звёздочки! ⭐')),
      );
    }
  }
}

/// Превью маскота в текущем наряде и счётчик звёзд.
class _Preview extends StatelessWidget {
  const _Preview({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.orange, AppTheme.yellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const MascotAvatar(size: 128),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.orange, size: 24),
                const SizedBox(width: 6),
                Text(
                  'У тебя: $stars ⭐',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Надень наряды на кота Байта — покупай их за звёздочки!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка одного аксессуара: эмодзи, имя, цена и кнопка действия.
class _AccessoryCard extends StatelessWidget {
  const _AccessoryCard({
    required this.accessory,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.onTap,
  });

  final Accessory accessory;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (equipped) {
      borderColor = AppTheme.teal;
    } else if (owned) {
      borderColor = AppTheme.yellow;
    } else {
      borderColor = const Color(0xFFDADFE6);
    }

    return Semantics(
      button: true,
      label: owned
          ? '${accessory.name}. ${equipped ? 'Надет' : 'Не надет'}'
          : '${accessory.name}. Цена ${accessory.price} звёзд',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: owned
                    ? AppTheme.yellow.withValues(alpha: 0.35)
                    : const Color(0xFFEDEFF3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(accessory.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 6),
            Text(
              accessory.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.orange, size: 16),
                const SizedBox(width: 2),
                Text(
                  '${accessory.price}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _actionButton(),
          ],
        ),
      ),
    );
  }

  Widget _actionButton() {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: equipped
          ? AppTheme.teal
          : (owned ? AppTheme.purple : AppTheme.orange),
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );

    if (owned) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: buttonStyle,
          child: Text(equipped ? 'Снять' : 'Надеть'),
        ),
      );
    }

    if (!canAfford) {
      // Мягкая подсказка: без наказаний, просто позови собрать ещё звёзд.
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: const Color(0xFFEDEFF3),
            disabledForegroundColor: const Color(0xFF9AA3B2),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          child: const Text(
            'Собери ещё звёздочки! ⭐',
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: buttonStyle,
        child: Text('Купить за ${accessory.price} ⭐',
            textAlign: TextAlign.center, maxLines: 2),
      ),
    );
  }
}
