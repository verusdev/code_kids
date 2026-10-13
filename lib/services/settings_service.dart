import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Пользовательские настройки: звуки и озвучка.
class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _storageKey = 'code_kids_settings_v1';

  bool _sound = true;
  bool _speech = true;

  /// Включены ли звуковые эффекты (щелчки и «фанфары»).
  bool get soundEnabled => _sound;

  /// Включена ли озвучка (чтение заданий голосом).
  bool get speechEnabled => _speech;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _sound = (map['sound'] as bool?) ?? true;
      _speech = (map['speech'] as bool?) ?? true;
    } catch (_) {
      // Повреждённые данные — оставляем значения по умолчанию.
    }
  }

  Future<void> setSound(bool value) async {
    if (_sound == value) return;
    _sound = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setSpeech(bool value) async {
    if (_speech == value) return;
    _speech = value;
    notifyListeners();
    await _persist();
  }

  @visibleForTesting
  Future<void> reset() async {
    _sound = true;
    _speech = true;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({'sound': _sound, 'speech': _speech}),
      );
    } catch (_) {
      // Игнорируем ошибки записи.
    }
  }
}
