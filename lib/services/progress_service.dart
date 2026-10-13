import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранит и сохраняет прогресс ребёнка: звёзды по каждому уровню каждой игры.
///
/// Ключ в SharedPreferences — строка JSON вида:
/// `{ "maze": [3, 2, 0, 0, 0, 0], "pattern": [3, 3, 0, 0, 0, 0] }`
/// где `0` означает «уровень ещё не пройден».
class ProgressService extends ChangeNotifier {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const String _storageKey = 'code_kids_progress_v1';

  final Map<String, List<int>> _stars = {};

  /// Загрузить сохранённый прогресс (вызывается один раз при старте).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _stars.clear();
      decoded.forEach((key, value) {
        _stars[key] = (value as List).map((e) => (e as num).toInt()).toList();
      });
      notifyListeners();
    } catch (_) {
      // Повреждённые данные не должны ронять приложение — просто начинаем заново.
    }
  }

  /// Звёзды за конкретный уровень (0 — не пройден).
  int starsFor(String gameId, int levelIndex) {
    final list = _stars[gameId];
    if (list == null || levelIndex < 0 || levelIndex >= list.length) return 0;
    return list[levelIndex];
  }

  /// Сумма звёзд по игре.
  int totalStars(String gameId) {
    final list = _stars[gameId];
    if (list == null) return 0;
    return list.fold<int>(0, (sum, v) => sum + v);
  }

  /// Снимок звёзд по всем играм: `{ gameId: [звёзды по уровням] }`.
  /// Используется для проверки достижений.
  Map<String, List<int>> get snapshot =>
      {for (final e in _stars.entries) e.key: List<int>.of(e.value)};

  /// Уровень разблокирован, если он первый или предыдущий уже пройден.
  bool isUnlocked(String gameId, int levelIndex) {
    if (levelIndex == 0) return true;
    return starsFor(gameId, levelIndex - 1) > 0;
  }

  /// Записать результат прохождения уровня (сохраняем лучший результат).
  Future<void> record(String gameId, int levelIndex, int stars, int levelCount) async {
    if (stars <= 0) return;
    final list = _stars.putIfAbsent(gameId, () => List<int>.filled(levelCount, 0));
    while (list.length < levelCount) {
      list.add(0);
    }
    if (stars > list[levelIndex]) {
      list[levelIndex] = stars;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_stars));
    } catch (_) {
      // Игнорируем ошибки записи, чтобы не мешать игре.
    }
  }

  /// Полный сброс прогресса (для отладки/родительского режима).
  Future<void> reset() async {
    _stars.clear();
    notifyListeners();
    await _persist();
  }
}
