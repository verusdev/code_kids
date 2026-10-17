import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/challenge_service.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti.dart';
import '../widgets/kid_button.dart';
import '../widgets/star_row.dart';
import '../widgets/task_speech_button.dart';

/// Верхняя панель игрового экрана с кнопкой «назад» и названием уровня.
/// Во время «Испытания» вместо названия уровня показывает таймер и номер
/// задания.
AppBar gameAppBar(GameInfo game, int levelIndex) {
  return AppBar(
    title: ChallengeSession.active
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🏆  Испытание',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              Text(
                game.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Text('${game.emoji}  Уровень ${levelIndex + 1}'),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Назад',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    ),
    actions: [
      if (ChallengeSession.active) const _ChallengeClock(),
      const SizedBox(width: 8),
    ],
  );
}

/// Таймер и номер задания в шапке во время испытания.
class _ChallengeClock extends StatelessWidget {
  const _ChallengeClock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${ChallengeSession.current}/${ChallengeSession.total}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            ValueListenableBuilder<int>(
              valueListenable: ChallengeSession.seconds,
              builder: (context, value, _) => Text(
                formatDuration(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Оверлей победы: конфетти, звёзды и кнопки продолжения.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.game,
    required this.stars,
    required this.maxLevelIndex,
    required this.onRetry,
  });

  final GameInfo game;
  final int stars;
  final int maxLevelIndex;
  final VoidCallback onRetry;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> {
  GameInfo get game => widget.game;
  int get stars => widget.stars;

  @override
  void initState() {
    super.initState();
    SoundService.win();
    SpeechService.instance.speak(_praise);
  }

  String get _praise {
    if (stars >= 3) return 'Вот это да! Всё верно! 🎉';
    if (stars == 2) return 'Отлично получилось! 👏';
    return 'Молодец, у тебя получилось! 🙂';
  }

  @override
  Widget build(BuildContext context) {
    final inChallenge = ChallengeSession.active;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Stack(
          children: [
            const Positioned.fill(child: Confetti()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(game.emoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 8),
                      Text(
                        _praise,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StarRow(stars: stars, size: 46),
                      if (inChallenge) ...[
                        const SizedBox(height: 20),
                        KidButton(
                          label:
                              ChallengeSession.current < ChallengeSession.total
                              ? 'Дальше'
                              : 'Завершить',
                          icon: Icons.arrow_forward_rounded,
                          color: AppTheme.pink,
                          expand: true,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ] else ...[
                        if (widget.maxLevelIndex > 0) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Новый уровень уже открыт! 🔓',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00B894),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        KidButton(
                          label: 'Ещё раз',
                          icon: Icons.replay_rounded,
                          color: AppTheme.orange,
                          expand: true,
                          onPressed: widget.onRetry,
                        ),
                        const SizedBox(height: 10),
                        KidButton(
                          label: 'К уровням',
                          icon: Icons.grid_view_rounded,
                          color: AppTheme.teal,
                          expand: true,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 10),
                        KidButton(
                          label: 'Домой',
                          icon: Icons.home_rounded,
                          color: AppTheme.purple,
                          expand: true,
                          onPressed: () =>
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка подсказки под игровым полем.
class HintBar extends StatefulWidget {
  const HintBar({
    super.key,
    required this.text,
    this.color,
    this.autoRead = true,
  });

  final String text;
  final Color? color;

  /// Читать текст голосом при появлении (озвучка задания на уровне).
  final bool autoRead;

  @override
  State<HintBar> createState() => _HintBarState();
}

class _HintBarState extends State<HintBar> {
  @override
  void initState() {
    super.initState();
    if (widget.autoRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SpeechService.instance.speak(widget.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Во время «Испытания» подсказки скрыты — нельзя подглядывать.
    if (ChallengeSession.active) return const SizedBox.shrink();
    final accent = widget.color ?? AppTheme.yellow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          TaskSpeechButton(text: widget.text, color: AppTheme.ink),
        ],
      ),
    );
  }
}
