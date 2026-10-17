import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../achievements/achievements.dart';
import '../models/achievement.dart';
import 'profile_service.dart';

/// Помнит, какие медали ребёнку уже «вручили» (показали всплывающее окно),
/// чтобы не показывать их повторно при каждом запуске.
///
/// Данные хранятся отдельно для каждого профиля ребёнка:
/// ключ `<base>::<profileId>` (см. [ProfileService.storageKey]).
/// Старые «глобальные» ключи при первом запуске мигрируются на профиль
/// по умолчанию и не удаляются.
class AchievementsService extends ChangeNotifier {
  AchievementsService._();

  static final AchievementsService instance = AchievementsService._();

  static const String _baseKey = 'code_kids_achievements_v1';

  final Set<String> _celebrated = {};

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacy(prefs);
      final raw = prefs.getString(_storageKey);
      final list = <String>[];
      if (raw != null && raw.isNotEmpty) {
        list.addAll((jsonDecode(raw) as List).cast<String>());
      }
      _celebrated
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // Повреждённые данные — просто начинаем заново.
    }
  }

  /// Перечитать выданные медали текущего профиля с диска
  /// (после смены профиля или импорта).
  Future<void> reload() async {
    _celebrated.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _celebrated.addAll((jsonDecode(raw) as List).cast<String>());
      }
    } catch (_) {
      // Повреждённые данные — начинаем заново.
    }
    notifyListeners();
  }

  /// Миграция: старый глобальный ключ (без профиля) принадлежит профилю
  /// по умолчанию. Старое значение не удаляется, повторный запуск
  /// ничего не делает (данные уже перенесены).
  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final defaultKey = ProfileService.instance
        .storageKeyFor(_baseKey, ProfileService.defaultProfileId);
    final existing = prefs.getString(defaultKey);
    if (existing != null && existing.isNotEmpty) return;
    final legacy = prefs.getString(_baseKey);
    if (legacy == null || legacy.isEmpty) return;
    await prefs.setString(defaultKey, legacy);
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

  /// Данные для экспорта: список идентификаторов выданных медалей.
  List<String> exportData() => _celebrated.toList();

  /// Восстановить выданные медали из импортированного списка идентификаторов.
  Future<void> importData(List<String> ids) async {
    _celebrated
      ..clear()
      ..addAll(ids);
    notifyListeners();
    await _persist();
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
