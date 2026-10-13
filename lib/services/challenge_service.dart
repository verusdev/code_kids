import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
class ChallengeService {
  ChallengeService._();

  static final ChallengeService instance = ChallengeService._();

  static const String _key = 'code_kids_challenge_v1';

  int _bestSeconds = 0;

  /// Лучшее время в секундах (0 — рекорда ещё нет).
  int get bestSeconds => _bestSeconds;

  bool get hasRecord => _bestSeconds > 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _bestSeconds = prefs.getInt(_key) ?? 0;
  }

  /// Записывает время, если оно лучше прежнего рекорда.
  /// Возвращает true, если это новый рекорд.
  Future<bool> record(int seconds) async {
    if (seconds <= 0) return false;
    if (_bestSeconds > 0 && seconds >= _bestSeconds) return false;
    _bestSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, seconds);
    return true;
  }

  Future<void> reset() async {
    _bestSeconds = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Красивое время вида «1:05» или «12:03».
String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
