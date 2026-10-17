import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

/// Учёт времени, проведённого ребёнком в приложении.
///
/// Данные отдельные для каждого профиля (ключ `<base>::<profileId>`).
/// Время накапливается небольшими «тиками» из таймера, запускаемого при
/// старте приложения (см. [startSession]). Хранится общее время и время
/// за сегодняшний день.
class PlaytimeService extends ChangeNotifier {
  PlaytimeService._() {
    ProfileService.instance.addListener(_onProfileChanged);
  }

  static final PlaytimeService instance = PlaytimeService._();

  static const String _baseKey = 'code_kids_playtime_v1';

  int _totalSeconds = 0;
  int _todaySeconds = 0;
  String _day = '';

  bool _running = false;
  Timer? _timer;

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  /// Всего секунд в приложении.
  int get totalSeconds => _totalSeconds;

  /// Секунд за сегодня.
  int get todaySeconds => _todaySeconds;

  /// Идёт ли сейчас учёт времени.
  bool get running => _running;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _totalSeconds = 0;
      _todaySeconds = 0;
      _day = _todayKey();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _totalSeconds = (map['total'] as num?)?.toInt() ?? 0;
        final savedDay = map['day'] as String? ?? '';
        if (savedDay == _day) {
          _todaySeconds = (map['today'] as num?)?.toInt() ?? 0;
        } else {
          _todaySeconds = 0;
        }
      }
      notifyListeners();
    } catch (_) {
      // Повреждённые данные — начинаем с нуля.
    }
  }

  Future<void> reload() => load();

  /// Запустить учёт времени (вызывается один раз при старте приложения).
  void startSession({Duration interval = const Duration(seconds: 30)}) {
    if (_running) return;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => addSeconds(interval.inSeconds));
  }

  /// Остановить учёт времени.
  void stopSession() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Добавить прошедшее время.
  void addSeconds(int seconds) {
    if (seconds <= 0) return;
    final today = _todayKey();
    if (today != _day) {
      _day = today;
      _todaySeconds = 0;
    }
    _totalSeconds += seconds;
    _todaySeconds += seconds;
    notifyListeners();
    unawaited(_persist());
  }

  @visibleForTesting
  Future<void> reset() async {
    _totalSeconds = 0;
    _todaySeconds = 0;
    _day = _todayKey();
    notifyListeners();
    await _persist();
  }

  void _onProfileChanged() {
    unawaited(reload());
  }

  String _todayKey() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'total': _totalSeconds,
          'today': _todaySeconds,
          'day': _day,
        }),
      );
    } catch (_) {
      // Игнорируем ошибки записи.
    }
  }

  /// Человекочитаемая длительность: «1 ч 5 мин», «12 мин», «40 с».
  static String formatDuration(int seconds) {
    if (seconds < 60) return '$seconds с';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final restMinutes = minutes % 60;
    if (restMinutes == 0) return '$hours ч';
    return '$hours ч $restMinutes мин';
  }
}
