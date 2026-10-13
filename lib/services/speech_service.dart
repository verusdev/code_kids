import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';

/// Озвучка: чтение заданий и подсказок голосом.
///
/// Работает через `flutter_tts` (системный синтез речи). Если он недоступен
/// (например, в некоторых браузерах или тестовой среде) — методы тихо ничего
/// не делают, чтобы игра не ломалась.
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  FlutterTts? _tts;
  bool _ready = false;

  /// Доступна ли озвучка на этом устройстве.
  bool get available => _ready;

  /// Настроить голос (русский, чуть медленнее обычного).
  Future<void> init() async {
    try {
      final tts = FlutterTts();
      await tts.setLanguage('ru-RU');
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.05);
      await tts.awaitSpeakCompletion(false);
      _tts = tts;
      _ready = true;
    } catch (e) {
      _ready = false;
      if (kDebugMode) {
        debugPrint('Озвучка недоступна: $e');
      }
    }
  }

  /// Произнести текст (если озвучка включена в настройках).
  Future<void> speak(String text) async {
    if (!SettingsService.instance.speechEnabled) return;
    final tts = _tts;
    if (!_ready || tts == null || text.trim().isEmpty) return;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // Синтез речи может быть недоступен — молча пропускаем.
    }
  }

  /// Остановить речь.
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
