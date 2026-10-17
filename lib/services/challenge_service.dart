import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

/// Общее состояние текущего «Испытания»: активно ли оно и какой идёт уровень.
///
/// Игры читают это состояние, чтобы во время испытания спрятать подсказки и
/// показать таймер и номер задания.
class ChallengeSession {
  ChallengeSession._();

  /// Идёт ли сейчас испытание.
  static bool active = false;

  /// Номер текущего задания (с 1) и всего заданий.
  static int current = 0;
  static int total = 0;

  /// Секунды с начала испытания (обновляется раз в секунду).
  static final ValueNotifier<int> seconds = ValueNotifier<int>(0);

  static void start(int totalTasks) {
    active = true;
    current = 0;
    total = totalTasks;
    seconds.value = 0;
  }

  static void stop() {
    active = false;
    current = 0;
    total = 0;
  }

  /// Только для тестов: вернуть состояние в исходное.
  @visibleForTesting
  static void reset() {
    active = false;
    current = 0;
    total = 0;
    seconds.value = 0;
  }
}

/// Рекорд «Испытания»: лучшее время прохождения всех заданий.
///
/// Данные хранятся отдельно для каждого профиля ребёнка:
/// ключ `<base>::<profileId>` (см. [ProfileService.storageKey]).
/// Старый «глобальный» ключ при первом запуске мигрируется на профиль
/// по умолчанию и не удаляется.
class ChallengeService extends ChangeNotifier {
  ChallengeService._();

  static final ChallengeService instance = ChallengeService._();

  static const String _baseKey = 'code_kids_challenge_v1';

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  int _bestSeconds = 0;

  /// Лучшее время в секундах (0 — рекорда ещё нет).
  int get bestSeconds => _bestSeconds;

  bool get hasRecord => _bestSeconds > 0;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacy(prefs);
      _bestSeconds = prefs.getInt(_storageKey) ?? 0;
    } catch (_) {
      _bestSeconds = 0;
    }
    notifyListeners();
  }

  /// Перечитать рекорд текущего профиля с диска (после смены профиля
  /// или импорта).
  Future<void> reload() async {
    _bestSeconds = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestSeconds = prefs.getInt(_storageKey) ?? 0;
    } catch (_) {
      _bestSeconds = 0;
    }
    notifyListeners();
  }

  /// Миграция: старый глобальный ключ (без профиля) принадлежит профилю
  /// по умолчанию. Старое значение не удаляется, повторный запуск
  /// ничего не делает (данные уже перенесены).
  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final defaultKey = ProfileService.instance
        .storageKeyFor(_baseKey, ProfileService.defaultProfileId);
    if (prefs.getInt(defaultKey) != null) return;
    final legacy = prefs.getInt(_baseKey);
    if (legacy == null) return;
    await prefs.setInt(defaultKey, legacy);
  }

  /// Записывает время, если оно лучше прежнего рекорда.
  /// Возвращает true, если это новый рекорд.
  Future<bool> record(int seconds) async {
    if (seconds <= 0) return false;
    if (_bestSeconds > 0 && seconds >= _bestSeconds) return false;
    _bestSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, seconds);
    return true;
  }

  /// Данные для экспорта: лучшее время в секундах (0 — рекорда нет).
  int exportData() => _bestSeconds;

  /// Восстановить рекорд из импортированного значения (некорректные
  /// значения приводятся к 0 — «рекорда нет»).
  Future<void> importData(int seconds) async {
    _bestSeconds = seconds > 0 ? seconds : 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, _bestSeconds);
    notifyListeners();
  }

  Future<void> reset() async {
    _bestSeconds = 0;
    // Пишем 0, а не удаляем ключ: иначе при следующем запуске миграция
    // снова скопирует старый глобальный рекорд, и данные «воскреснут».
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, 0);
    notifyListeners();
  }
}

/// Красивое время вида «1:05» или «12:03».
String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
