import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/speech_service.dart';

/// Кнопка «прочитать вслух». Если озвучка выключена в настройках —
/// кнопка не показывается (чтобы не сбивать ребёнка с толку).
class TaskSpeechButton extends StatelessWidget {
  const TaskSpeechButton({
    super.key,
    required this.text,
    this.color,
    this.label,
  });

  final String text;
  final Color? color;

  /// Подпись рядом с иконкой. Если не задана — только иконка.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, _) {
        if (!SettingsService.instance.speechEnabled) {
          return const SizedBox.shrink();
        }
        final accent = color ?? Theme.of(context).colorScheme.primary;
        if (label == null) {
          return IconButton(
            tooltip: 'Прочитать вслух',
            onPressed: () => SpeechService.instance.speak(text),
            icon: Icon(Icons.volume_up_rounded, color: accent),
          );
        }
        return TextButton.icon(
          onPressed: () => SpeechService.instance.speak(text),
          icon: Icon(Icons.volume_up_rounded, color: accent),
          label: Text(
            label!,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
