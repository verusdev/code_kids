import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../achievements/achievements.dart';
import '../models/achievement.dart';

/// Помнит, какие медали ребёнку уже «вручили» (показали всплывающее окно),
/// чтобы не показывать их повторно при каждом запуске.
class AchievementsService extends ChangeNotifier {
  AchievementsService._();

  static final AchievementsService instance = AchievementsService._();

  static const String _storageKey = 'code_kids_achievements_v1';

  final Set<String> _celebrated = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).cast<String>();
      _celebrated
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // Повреждённые данные — просто начинаем заново.
    }
  }

  bool isCelebrated(String id) => _celebrated.contains(id);

  /// Сколько медалей уже вручено.
  int get celebratedCount =>
      kAchievements.where((a) => _celebrated.contains(a.id)).length;

  /// Возвращает только что открытые медали и помечает их как вручённые.
  List<Achievement> takeNewlyUnlocked(ProgressSnapshot snapshot) {
    final fresh = kAchievements
        .where((a) => a.isUnlocked(snapshot) && !_celebrated.contains(a.id))
        .toList();
    if (fresh.isEmpty) return const [];
    for (final a in fresh) {
      _celebrated.add(a.id);
    }
    notifyListeners();
    _persist();
    return fresh;
  }

  Future<void> reset() async {
    _celebrated.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_celebrated.toList()));
    } catch (_) {
      // Игнорируем ошибки записи.
    }
  }
}
