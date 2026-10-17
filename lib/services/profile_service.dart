import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Пресет аватаров для профиля — крупные дружелюбные эмодзи.
const List<String> kProfileEmojis = [
  '🧒',
  '👧',
  '👦',
  '🧑',
  '🐻',
  '🦊',
  '🐱',
  '🐼',
  '🐸',
  '🤖',
  '👑',
  '🚀',
];

/// Профиль ребёнка: имя и аватар-эмодзи.
///
/// Прогресс каждого профиля хранится в отдельных ключах SharedPreferences
/// (см. [ProfileService.storageKey]).
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.emoji,
  });

  /// Уникальный идентификатор (генерируется как `'p' + время + счётчик + случайный хвост`).
  final String id;

  /// Имя ребёнка (без пустых краёв, до 20 символов).
  final String name;

  /// Аватар-эмодзи.
  final String emoji;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  static Profile? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final emoji = json['emoji'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    return Profile(
      id: id,
      name: name,
      emoji: emoji is String && emoji.isNotEmpty ? emoji : '🧒',
    );
  }
}

/// Управляет профилями детей: хранит список профилей и текущий активный.
///
/// Ключ в SharedPreferences — строка JSON вида:
/// `{ "profiles": [...], "currentId": "p1760..." }`.
///
/// Все прогресс-сервисы хранят данные по ключу `<базовый ключ>::<profileId>`
/// (см. [storageKey]), поэтому при смене профиля их нужно перечитать
/// методом `reload()`.
class ProfileService extends ChangeNotifier {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  static const String _storageKey = 'code_kids_profiles_v1';

  /// Идентификатор профиля по умолчанию (создаётся при первом запуске).
  static const String defaultProfileId = 'default';

  /// Монотонный счётчик вызовов генератора id — гарантирует уникальность,
  /// даже если системные часы вернут одно и то же время (частая проблема
  /// на Windows с грубым разрешением `DateTime.now().microsecondsSinceEpoch`).
  static int _idSeq = 0;

  /// Источник случайного хвоста id — защищает от совпадений между запусками.
  static final Random _idRandom = Random();

  final List<Profile> _profiles = [];
  String _currentId = defaultProfileId;

  /// Все профиля в порядке создания.
  List<Profile> get profiles => List.unmodifiable(_profiles);

  /// Идентификатор текущего профиля.
  String get currentId => _currentId;

  /// Текущий профиль (до загрузки возвращает профиль по умолчанию).
  Profile get current {
    for (final p in _profiles) {
      if (p.id == _currentId) return p;
    }
    return const Profile(id: defaultProfileId, name: 'Друг', emoji: '🧒');
  }

  /// Ключ хранилища для данных [base], принадлежащих текущему профилю.
  String storageKey(String base) => storageKeyFor(base, currentId);

  /// Ключ хранилища для данных [base], принадлежащих профилю [profileId].
  String storageKeyFor(String base, String profileId) => '$base::$profileId';

  /// Загрузить список профилей (вызывается один раз при старте, до остальных
  /// сервисов — чтобы они знали текущий профиль).
  ///
  /// Если профилей ещё нет, создаётся профиль по умолчанию «Друг».
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _profiles.clear();
          final list = decoded['profiles'];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final profile = Profile.fromJson(item);
                if (profile != null) _profiles.add(profile);
              }
            }
          }
          final currentId = decoded['currentId'];
          if (currentId is String) _currentId = currentId;
        }
      }
    } catch (_) {
      // Повреждённые данные не должны ронять приложение — начнём заново.
    }

    var changed = false;
    if (_profiles.isEmpty) {
      _profiles
        ..clear()
        ..add(const Profile(
          id: defaultProfileId,
          name: 'Друг',
          emoji: '🧒',
        ));
      _currentId = defaultProfileId;
      changed = true;
    }
    if (!_profiles.any((p) => p.id == _currentId)) {
      _currentId = _profiles.first.id;
      changed = true;
    }
    if (changed) await _persist();
    notifyListeners();
  }

  /// Переключиться на профиль [id] и уведомить слушателей.
  ///
  /// После переключения прогресс-сервисы нужно перечитать (`reload()`).
  Future<void> switchTo(String id) async {
    if (!_profiles.any((p) => p.id == id)) return;
    if (_currentId == id) return;
    _currentId = id;
    notifyListeners();
    await _persist();
  }

  /// Добавить новый профиль и вернуть его.
  Profile add(String name, String emoji) {
    final profile = Profile(
      id: _generateId(),
      name: _cleanName(name),
      emoji: emoji.isNotEmpty ? emoji : '🧒',
    );
    _profiles.add(profile);
    notifyListeners();
    _persist();
    return profile;
  }

  /// Гарантированно уникальный идентификатор профиля.
  ///
  /// К времени в микросекундах добавляем монотонный счётчик и случайный хвост:
  /// так id не совпадут даже при нескольких вызовах в одном тике.
  /// Формат id остаётся обычной строкой, поэтому ранее сохранённые данные
  /// по-прежнему читаются.
  static String _generateId() {
    _idSeq++;
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = _idRandom.nextInt(0x100000000).toRadixString(36);
    return 'p$ts-${_idSeq.toRadixString(36)}-$rnd';
  }

  /// Переименовать профиль / сменить аватар.
  Future<void> rename(String id, {String? name, String? emoji}) async {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final old = _profiles[index];
    final newName = name != null ? _cleanName(name) : old.name;
    final newEmoji = emoji != null && emoji.isNotEmpty ? emoji : old.emoji;
    if (newName == old.name && newEmoji == old.emoji) return;
    _profiles[index] = Profile(id: id, name: newName, emoji: newEmoji);
    notifyListeners();
    await _persist();
  }

  /// Удалить профиль. Нельзя удалить последний профиль.
  ///
  /// Если удаляется текущий профиль — переключаемся на первый в списке.
  /// Возвращает `true`, если профиль был удалён.
  Future<bool> remove(String id) async {
    if (_profiles.length <= 1) return false;
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    _profiles.removeAt(index);
    if (_currentId == id) {
      _currentId = _profiles.first.id;
    }
    notifyListeners();
    await _persist();
    return true;
  }

  /// Имя без пустых краёв, не длиннее 20 символов.
  static String _cleanName(String name) {
    var cleaned = name.trim();
    if (cleaned.isEmpty) cleaned = 'Друг';
    if (cleaned.length > 20) cleaned = cleaned.substring(0, 20);
    return cleaned;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'profiles': _profiles.map((p) => p.toJson()).toList(),
          'currentId': _currentId,
        }),
      );
    } catch (_) {
      // Игнорируем ошибки записи, чтобы не мешать игре.
    }
  }
}
