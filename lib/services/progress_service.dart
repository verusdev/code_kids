import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

/// Хранит и сохраняет прогресс ребёнка: звёзды по каждому уровню каждой игры.
///
/// Ключ в SharedPreferences — строка JSON вида:
/// `{ "maze": [3, 2, 0, 0, 0, 0], "pattern": [3, 3, 0, 0, 0, 0] }`
/// где `0` означает «уровень ещё не пройден».
///
/// Данные хранятся отдельно для каждого профиля ребёнка:
/// ключ `<base>::<profileId>` (см. [ProfileService.storageKey]).
/// Старые «глобальные» ключи (без профиля) при первом запуске мигрируются
/// на профиль по умолчанию и не удаляются.
class ProgressService extends ChangeNotifier {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const String _baseKey = 'code_kids_progress_v1';

  final Map<String, List<int>> _stars = {};

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  /// Загрузить сохранённый прогресс (вызывается один раз при старте).
  ///
  /// Старые «глобальные» данные без профиля при первом запуске мигрируются
  /// на профиль по умолчанию (см. [ProfileService.defaultProfileId]).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacy(prefs);
      final raw = prefs.getString(_storageKey);
      _stars.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _stars[key] = (value as List).map((e) => (e as num).toInt()).toList();
        });
      }
      notifyListeners();
    } catch (_) {
      // Повреждённые данные не должны ронять приложение — просто начинаем заново.
    }
  }

  /// Миграция: старый глобальный ключ (без профиля) принадлежит профилю
  /// по умолчанию. Старое значение не удаляется, повторный запуск
  /// ничего не делает (данные уже перенесены).
  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final defaultKey = ProfileService.instance.storageKeyFor(
      _baseKey,
      ProfileService.defaultProfileId,
    );
    final existing = prefs.getString(defaultKey);
    if (existing != null && existing.isNotEmpty) return;
    final legacy = prefs.getString(_baseKey);
    if (legacy == null || legacy.isEmpty) return;
    await prefs.setString(defaultKey, legacy);
  }

  /// Перечитать прогресс текущего профиля с диска (после смены профиля
  /// или импорта). Внутреннее состояние при этом полностью сбрасывается.
  Future<void> reload() async {
    _stars.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _stars[key] = (value as List).map((e) => (e as num).toInt()).toList();
        });
      }
    } catch (_) {
      // Повреждённые данные — начинаем заново.
    }
    notifyListeners();
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
  Map<String, List<int>> get snapshot => {
    for (final e in _stars.entries) e.key: List<int>.of(e.value),
  };

  /// Уровень разблокирован, если он первый или предыдущий уже пройден.
  bool isUnlocked(String gameId, int levelIndex) {
    if (levelIndex == 0) return true;
    return starsFor(gameId, levelIndex - 1) > 0;
  }

  /// Индекс текущего (первого непройденного) уровня игры.
  /// Если все уровни пройдены — возвращает последний.
  int currentLevel(String gameId, int levelCount) {
    for (int i = 0; i < levelCount; i++) {
      if (starsFor(gameId, i) == 0) return i;
    }
    return levelCount > 0 ? levelCount - 1 : 0;
  }

  /// Сколько уровней пройдено (со звёздами) в игре.
  int levelsPassed(String gameId, int levelCount) {
    int passed = 0;
    for (int i = 0; i < levelCount; i++) {
      if (starsFor(gameId, i) > 0) passed++;
    }
    return passed;
  }

  /// Записать результат прохождения уровня (сохраняем лучший результат).
  Future<void> record(
    String gameId,
    int levelIndex,
    int stars,
    int levelCount,
  ) async {
    if (stars <= 0) return;
    final list = _stars.putIfAbsent(
      gameId,
      () => List<int>.filled(levelCount, 0),
    );
    while (list.length < levelCount) {
      list.add(0);
    }
    if (stars > list[levelIndex]) {
      list[levelIndex] = stars;
      notifyListeners();
      await _persist();
    }
  }

  /// Сумма всех звёзд профиля [profileId] — для экрана выбора профиля.
  ///
  /// Читает хранилище напрямую и не трогает текущее состояние сервиса,
  /// поэтому можно безопасно посчитать звёзды любого профиля.
  Future<int> totalStarsForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = ProfileService.instance.storageKeyFor(_baseKey, profileId);
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return 0;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      var total = 0;
      for (final value in decoded.values) {
        if (value is! List) continue;
        for (final item in value) {
          if (item is num) total += item.toInt();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Данные для экспорта: `{ gameId: [звёзды по уровням] }`.
  Map<String, dynamic> exportData() => snapshot;

  /// Восстановить прогресс из импортированной карты `{ gameId: [звёзды] }`.
  ///
  /// Некорректные записи пропускаются, чтобы мусор из буфера обмена
  /// не ломал приложение.
  Future<void> importData(Map<String, dynamic> data) async {
    _stars.clear();
    data.forEach((key, value) {
      if (value is! List) return;
      _stars[key] = value
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(growable: false);
    });
    notifyListeners();
    await _persist();
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
