import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Короткие звуки и вибрация. Работает без звуковых файлов —
/// использует системные звуки и тактильную отдачу.
class SoundService {
  SoundService._();

  /// Лёгкий щелчок при нажатии.
  static Future<void> tap() async {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // На некоторых платформах системный звук недоступен — не мешаем игре.
    }
  }

  /// Радостный звук при победе.
  static Future<void> win() async {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Мягкий сигнал при ошибке.
  static Future<void> wrong() async {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
