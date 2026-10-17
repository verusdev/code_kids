import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../services/daily_service.dart';
import '../services/mascot_service.dart';
import '../services/progress_service.dart';
import '../stickers/stickers.dart';
import '../theme/app_theme.dart';

/// Экран «📖 Наклейки» — альбом коллекционных картинок.
///
/// Открытые наклейки показываются цветными, закрытые — серыми с замком
/// и подсказкой, как их получить.
class StickersScreen extends StatelessWidget {
  const StickersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('📖 Наклейки')),
      body: ListenableBuilder(
        // Снимок зависит от звёзд, серии дней и магазина нарядов.
        listenable: Listenable.merge([
          progress,
          DailyService.instance,
          MascotService.instance,
        ]),
        builder: (context, _) {
          final snapshot = currentSnapshot();
          final unlocked = unlockedStickerCount(snapshot);
          final total = kStickers.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(unlocked: unlocked, total: total),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: kStickers.length,
                itemBuilder: (context, index) {
                  final sticker = kStickers[index];
                  return _StickerCard(
                    sticker: sticker,
                    unlocked: sticker.isUnlocked(snapshot),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Шапка альбома: «Открыто: X из N» и полоса прогресса.
class _Header extends StatelessWidget {
  const _Header({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final done = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.purple, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Открыто: $unlocked из $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: done,
              minHeight: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFFFFF)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Играй и собирай звёзды — за это открываются новые наклейки!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка одной наклейки: открытая — цветная, закрытая — серая с замком.
class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.sticker, required this.unlocked});

  final Sticker sticker;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: unlocked
          ? '${sticker.name}. Открыта'
          : '${sticker.name}. Закрыта. ${sticker.hint}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: unlocked ? AppTheme.yellow : const Color(0xFFDADFE6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.yellow.withValues(alpha: 0.35)
                    : const Color(0xFFEDEFF3),
                shape: BoxShape.circle,
              ),
              child: Text(
                unlocked ? sticker.emoji : '🔒',
                style: const TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sticker.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: unlocked ? AppTheme.ink : const Color(0xFF9AA3B2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked ? 'Открыта! 🎉' : sticker.hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: unlocked ? AppTheme.teal : const Color(0xFF9AA3B2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
