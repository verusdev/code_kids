import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../python/python_interpreter.dart';
import 'profile_service.dart';

/// Один сохранённый рисунок черепашки из Песочницы.
class TurtleDrawing {
  const TurtleDrawing({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.segments,
  });

  /// Уникальный идентификатор (`'d' + время + счётчик + случайный хвост`).
  final String id;

  /// Имя рисунка, придуманное ребёнком.
  final String name;

  /// Когда нарисован (мс с эпохи Unix).
  final int createdAt;

  /// Отрезки линий, которые оставила черепашка.
  final List<TurtleSegment> segments;

  /// Сериализация: `[[x1, y1, x2, y2], …]` — по одному массиву на отрезок.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'segments': segments
            .map((s) => [s.x1, s.y1, s.x2, s.y2])
            .toList(growable: false),
      };

  /// Разобрать запись из хранилища; повреждённые записи пропускаются.
  static TurtleDrawing? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    final rawSegments = json['segments'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (createdAt is! num) return null;
    if (rawSegments is! List) return null;
    final segments = <TurtleSegment>[];
    for (final item in rawSegments) {
      if (item is! List || item.length < 4) continue;
      final values = item.take(4).whereType<num>().toList();
      if (values.length < 4) continue;
      segments.add(TurtleSegment(
        values[0].toDouble(),
        values[1].toDouble(),
        values[2].toDouble(),
        values[3].toDouble(),
      ));
    }
    return TurtleDrawing(
      id: id,
      name: name,
      createdAt: createdAt.toInt(),
      segments: segments,
    );
  }
}

/// Хранит галерею рисунков черепашки (Песочница → «Сохранить рисунок»).
///
/// Ключ в SharedPreferences — JSON-массив записей
/// `[{ "id": "d…", "name": "Рисунок 1", "createdAt": 1729…, "segments": [[x1,y1,x2,y2], …] }, …]`.
///
/// Данные хранятся отдельно для каждого профиля ребёнка:
/// ключ `<base>::<profileId>` (см. [ProfileService.storageKey]).
/// Хранится не больше [maxDrawings] последних рисунков — старые вытесняются.
class TurtleGalleryService extends ChangeNotifier {
  TurtleGalleryService._();

  static final TurtleGalleryService instance = TurtleGalleryService._();

  static const String _baseKey = 'code_kids_turtle_gallery_v1';

  /// Сколько последних рисунков хранится (старые удаляются).
  static const int maxDrawings = 30;

  /// Монотонный счётчик вызовов генератора id — гарантирует уникальность,
  /// даже если системные часы вернут одно и то же время (частая проблема
  /// на Windows с грубым разрешением `DateTime.now().microsecondsSinceEpoch`).
  static int _idSeq = 0;

  /// Источник случайного хвоста id — защищает от совпадений между запусками.
  static final Random _idRandom = Random();

  final List<TurtleDrawing> _drawings = [];
  bool _loaded = false;

  /// Все рисунки, новые — впереди.
  List<TurtleDrawing> get drawings => List.unmodifiable(_drawings);

  /// Загружены ли данные с диска.
  bool get isLoaded => _loaded;

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  /// Загрузить галерею текущего профиля (можно вызывать повторно —
  /// например, при каждом открытии экрана галереи или после смены профиля).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _drawings.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map<String, dynamic>) continue;
            final drawing = TurtleDrawing.fromJson(item);
            if (drawing != null) _drawings.add(drawing);
          }
        }
      }
    } catch (_) {
      // Повреждённые данные не должны ронять приложение — начнём заново.
      _drawings.clear();
    }
    _loaded = true;
    notifyListeners();
  }

  /// Сохранить новый рисунок (он становится первым в списке).
  ///
  /// Если рисунков больше [maxDrawings], самые старые удаляются.
  Future<void> add(String name, List<TurtleSegment> segments) async {
    if (!_loaded) await load();
    var cleaned = name.trim();
    if (cleaned.isEmpty) cleaned = 'Рисунок';
    _drawings.insert(
      0,
      TurtleDrawing(
        id: _generateId(),
        name: cleaned,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        segments: List.of(segments),
      ),
    );
    while (_drawings.length > maxDrawings) {
      _drawings.removeLast();
    }
    notifyListeners();
    await _persist();
  }

  /// Гарантированно уникальный идентификатор рисунка.
  ///
  /// К времени в микросекундах добавляем монотонный счётчик и случайный хвост:
  /// так id не совпадут даже при нескольких вызовах в одном тике.
  /// Формат id остаётся обычной строкой, поэтому ранее сохранённые данные
  /// по-прежнему читаются.
  static String _generateId() {
    _idSeq++;
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = _idRandom.nextInt(0x100000000).toRadixString(36);
    return 'd$ts-${_idSeq.toRadixString(36)}-$rnd';
  }

  /// Удалить рисунок по идентификатору.
  Future<void> remove(String id) async {
    if (!_loaded) await load();
    final index = _drawings.indexWhere((d) => d.id == id);
    if (index < 0) return;
    _drawings.removeAt(index);
    notifyListeners();
    await _persist();
  }

  /// Удалить все рисунки.
  Future<void> clear() async {
    if (!_loaded) await load();
    if (_drawings.isEmpty) return;
    _drawings.clear();
    notifyListeners();
    await _persist();
  }

  /// Данные для экспорта (для будущего бэкапа).
  Map<String, dynamic> exportData() => {
        'drawings': _drawings.map((d) => d.toJson()).toList(growable: false),
      };

  /// Восстановить галерею из импортированной карты.
  ///
  /// Некорректные записи пропускаются, чтобы мусор из буфера обмена
  /// не ломал приложение. Применяется лимит [maxDrawings].
  Future<void> importData(Map<String, dynamic> data) async {
    final restored = <TurtleDrawing>[];
    final list = data['drawings'];
    if (list is List) {
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final drawing = TurtleDrawing.fromJson(item);
        if (drawing != null) restored.add(drawing);
      }
    }
    _drawings
      ..clear()
      ..addAll(restored.take(maxDrawings));
    _loaded = true;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_drawings.map((d) => d.toJson()).toList(growable: false)),
      );
    } catch (_) {
      // Игнорируем ошибки записи, чтобы не мешать игре.
    }
  }
}
