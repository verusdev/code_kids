import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot.dart';

/// Настройки: звуки и озвучка (чтение заданий голосом).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Mascot(
                message:
                    'Здесь можно включить или выключить звуки и голос. '
                    'Настройки сохраняются — их не нужно задавать заново.',
                emoji: '⚙️',
              ),
              const SizedBox(height: 20),

              // Звуки.
              _SettingTile(
                emoji: '🔊',
                title: 'Звуки',
                subtitle: 'Щелчки при нажатии и весёлый сигнал при победе',
                value: _settings.soundEnabled,
                color: AppTheme.teal,
                onChanged: (v) async {
                  await _settings.setSound(v);
                  if (v) await SoundService.win();
                },
                action: _settings.soundEnabled
                    ? TextButton.icon(
                        onPressed: () => SoundService.win(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Проверить'),
                      )
                    : null,
              ),
              const SizedBox(height: 14),

              // Озвучка.
              _SettingTile(
                emoji: '🗣️',
                title: 'Озвучка',
                subtitle: 'Чтение заданий голосом',
                value: _settings.speechEnabled,
                color: AppTheme.sky,
                onChanged: (v) async {
                  await _settings.setSpeech(v);
                  if (v) {
                    await SpeechService.instance
                        .speak('Привет! Я умею читать задания.');
                  } else {
                    await SpeechService.instance.stop();
                  }
                },
                action: _settings.speechEnabled
                    ? TextButton.icon(
                        onPressed: () async {
                          final speech = SpeechService.instance;
                          if (!speech.available) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'На этом устройстве голос недоступен 😔',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          await speech.speak('Привет! Я умею читать задания.');
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Проверить'),
                      )
                    : null,
              ),

              if (!SpeechService.instance.available) ...[
                const SizedBox(height: 12),
                const _Hint(
                  text:
                      'Голос недоступен на этом устройстве. Обычно он работает '
                      'на телефонах и в большинстве браузеров.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Строка настройки с крупным переключателем.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
    this.action,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value ? 'Включено' : 'Выключено',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: value ? color : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: color,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          if (action != null) ...[
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: action!),
          ],
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
