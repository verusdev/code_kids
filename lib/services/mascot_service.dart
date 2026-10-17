import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';
import 'progress_service.dart';

/// Слот, в который можно надеть аксессуар.
///
/// В каждом слоте помещается не больше одного аксессуара одновременно,
/// поэтому полный наряд кота — это максимум три предмета сразу.
enum AccessorySlot {
  /// Головные уборы (🎩, 👑, 🧢 …) — рисуются над головой.
  hat('hat'),

  /// Очки и украшения на мордочку (🕶️, 😎, 🎀 …).
  face('face'),

  /// Дополнительные детали (🧣, 🎻 …) — у основания круга.
  extra('extra');

  const AccessorySlot(this.key);

  /// Строковый ключ слота для хранения в SharedPreferences.
  final String key;

  /// Разобрать слот из строкового ключа (неизвестное значение → `null`).
  static AccessorySlot? fromKey(String key) {
    for (final slot in values) {
      if (slot.key == key) return slot;
    }
    return null;
  }
}

/// Аксессуар для маскота — кота Байта.
///
/// Аксессуары покупаются в магазине «🛒 Наряды» за звёзды, а потом их можно
/// надеть на кота. В каждом [slot] одновременно живёт не больше одного
/// аксессуара, поэтому «надеть» новый заменяет прежний в этом слоте.
class Accessory {
  const Accessory({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.slot,
  });

  /// Уникальный идентификатор (используется как ключ хранения).
  final String id;

  /// Эмодзи аксессуара.
  final String emoji;

  /// Название, понятное ребёнку.
  final String name;

  /// Цена в звёздах (от 10 до 60).
  final int price;

  /// Слот, в который надевается аксессуар.
  final AccessorySlot slot;
}

/// Каталог всех аксессуаров магазина (14 штук, эмодзи не повторяются).
const List<Accessory> kAccessories = [
  // Слот «голова».
  Accessory(
    id: 'hat_cap',
    emoji: '🧢',
    name: 'Спортсмен',
    price: 15,
    slot: AccessorySlot.hat,
  ),
  Accessory(
    id: 'hat_helmet',
    emoji: '🪖',
    name: 'Смельчак',
    price: 25,
    slot: AccessorySlot.hat,
  ),
  Accessory(
    id: 'hat_music',
    emoji: '🎧',
    name: 'Меломан',
    price: 30,
    slot: AccessorySlot.hat,
  ),
  Accessory(
    id: 'hat_grad',
    emoji: '🎓',
    name: 'Умник',
    price: 35,
    slot: AccessorySlot.hat,
  ),
  Accessory(
    id: 'hat_wizard',
    emoji: '🎩',
    name: 'Волшебник',
    price: 45,
    slot: AccessorySlot.hat,
  ),
  Accessory(
    id: 'hat_crown',
    emoji: '👑',
    name: 'Король',
    price: 60,
    slot: AccessorySlot.hat,
  ),

  // Слот «мордочка».
  Accessory(
    id: 'face_bow',
    emoji: '🎀',
    name: 'Модница',
    price: 10,
    slot: AccessorySlot.face,
  ),
  Accessory(
    id: 'face_glasses',
    emoji: '🕶️',
    name: 'Крутой',
    price: 20,
    slot: AccessorySlot.face,
  ),
  Accessory(
    id: 'face_sun',
    emoji: '😎',
    name: 'Звезда',
    price: 30,
    slot: AccessorySlot.face,
  ),
  Accessory(
    id: 'face_goggles',
    emoji: '🥽',
    name: 'Ныряльщик',
    price: 35,
    slot: AccessorySlot.face,
  ),

  // Слот «дополнительно».
  Accessory(
    id: 'extra_scarf',
    emoji: '🧣',
    name: 'Тёплый шарф',
    price: 20,
    slot: AccessorySlot.extra,
  ),
  Accessory(
    id: 'extra_karate',
    emoji: '🥋',
    name: 'Каратист',
    price: 35,
    slot: AccessorySlot.extra,
  ),
  Accessory(
    id: 'extra_violin',
    emoji: '🎻',
    name: 'Музыкант',
    price: 40,
    slot: AccessorySlot.extra,
  ),
  Accessory(
    id: 'extra_medal',
    emoji: '🏅',
    name: 'Чемпион',
    price: 50,
    slot: AccessorySlot.extra,
  ),
];

/// Найти аксессуар по идентификатору (или `null`, если такого нет).
Accessory? accessoryById(String id) {
  for (final accessory in kAccessories) {
    if (accessory.id == id) return accessory;
  }
  return null;
}

/// Магазин нарядов кота Байта: какие аксессуары куплены и что надето сейчас.
///
/// Валюта — звёзды за все игры и Python-курс (см. [ProgressService]).
/// Потраченные звёзды запоминаются отдельно ([spentStars]), поэтому покупка
/// уменьшает доступный запас, но «заработанные» звёзды и медали не теряются.
///
/// Ключ в SharedPreferences — строка JSON вида:
/// `{ "owned": ["hat_wizard", …], "equipped": {"hat": "hat_wizard"}, "spent": 120 }`
/// Данные хранятся отдельно для каждого профиля ребёнка:
/// ключ `<base>::<profileId>` (см. [ProfileService.storageKey]).
class MascotService extends ChangeNotifier {
  MascotService._() {
    // При смене профиля перечитываем наряд нового ребёнка.
    ProfileService.instance.addListener(_onProfileChanged);
  }

  static final MascotService instance = MascotService._();

  static const String _baseKey = 'code_kids_shop_v1';

  final Set<String> _owned = {};
  final Map<AccessorySlot, String> _equipped = {};
  int _spent = 0;
  bool _loaded = false;
  bool _loading = false;

  /// Ключ хранилища текущего профиля.
  String get _storageKey => ProfileService.instance.storageKey(_baseKey);

  /// Загружены ли данные с диска.
  bool get isLoaded => _loaded;

  /// Сколько нарядов уже куплено.
  int get ownedCount {
    _ensureLoaded();
    return _owned.length;
  }

  /// Куплен ли аксессуар с идентификатором [id].
  bool isOwned(String id) {
    _ensureLoaded();
    return _owned.contains(id);
  }

  /// Сколько звёзд уже потрачено в магазине.
  int get spentStars {
    _ensureLoaded();
    return _spent;
  }

  /// Всего заработано звёзд по всем играм и Python-курсу.
  int get totalStars {
    var total = 0;
    for (final list in ProgressService.instance.snapshot.values) {
      total += list.fold<int>(0, (sum, value) => sum + value);
    }
    return total;
  }

  /// Сколько звёзд можно потратить (заработано минус потрачено).
  int get stars {
    _ensureLoaded();
    final left = totalStars - _spent;
    return left < 0 ? 0 : left;
  }

  /// Идентификатор аксессуара, надетого в слоте [slot] (или `null`).
  String? equippedId(AccessorySlot slot) {
    _ensureLoaded();
    return _equipped[slot];
  }

  /// Эмодзи аксессуара, надетого в слоте [slot] (или `null`).
  String? emojiForSlot(AccessorySlot slot) {
    final id = equippedId(slot);
    if (id == null) return null;
    return accessoryById(id)?.emoji;
  }

  /// Надет ли сейчас этот аксессуар.
  bool isEquipped(Accessory accessory) {
    _ensureLoaded();
    return _equipped[accessory.slot] == accessory.id;
  }

  /// Эмодзи надетых аксессуаров (по порядку слотов) — для рендера наряда.
  List<String> get equippedEmojis {
    _ensureLoaded();
    final result = <String>[];
    for (final slot in AccessorySlot.values) {
      final id = _equipped[slot];
      if (id == null) continue;
      final accessory = accessoryById(id);
      if (accessory != null) result.add(accessory.emoji);
    }
    return result;
  }

  /// Купить аксессуар.
  ///
  /// Возвращает `false`, если он уже куплен или звёзд не хватает —
  /// без наказаний, просто «попробуй позже». При успехе звёзды списываются
  /// ([spentStars] растёт) и слушатели уведомляются.
  Future<bool> buy(Accessory accessory) async {
    if (!_loaded) await load();
    if (_owned.contains(accessory.id)) return false;
    if (stars < accessory.price) return false;
    _owned.add(accessory.id);
    _spent += accessory.price;
    notifyListeners();
    await _persist();
    return true;
  }

  /// Надеть купленный аксессуар (заменяет предмет в том же слоте).
  Future<void> equip(Accessory accessory) async {
    if (!_loaded) await load();
    if (!_owned.contains(accessory.id)) return;
    if (_equipped[accessory.slot] == accessory.id) return;
    _equipped[accessory.slot] = accessory.id;
    notifyListeners();
    await _persist();
  }

  /// Снять аксессуар из слота [slot].
  Future<void> unequip(AccessorySlot slot) async {
    if (!_loaded) await load();
    if (!_equipped.containsKey(slot)) return;
    _equipped.remove(slot);
    notifyListeners();
    await _persist();
  }

  /// Надеть или снять аксессуар (удобно для кнопки «Надеть / Снять»).
  Future<void> toggle(Accessory accessory) async {
    if (isEquipped(accessory)) {
      await unequip(accessory.slot);
    } else {
      await equip(accessory);
    }
  }

  /// Загрузить покупки и наряд текущего профиля.
  ///
  /// Можно вызывать повторно — например, при открытии магазина или после
  /// смены профиля (в этом случае [MascotService] перечитывает данные сам).
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _owned.clear();
      _equipped.clear();
      _spent = 0;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final owned = decoded['owned'];
          if (owned is List) {
            for (final id in owned) {
              if (id is String && accessoryById(id) != null) _owned.add(id);
            }
          }
          final equipped = decoded['equipped'];
          if (equipped is Map) {
            equipped.forEach((key, value) {
              if (key is! String || value is! String) return;
              final slot = AccessorySlot.fromKey(key);
              if (slot == null) return;
              // Надеваем только то, что действительно куплено.
              if (_owned.contains(value)) _equipped[slot] = value;
            });
          }
          final spent = decoded['spent'];
          if (spent is num) _spent = spent.toInt();
        }
      }
    } catch (_) {
      // Повреждённые данные не должны ронять приложение — начнём заново.
      _owned.clear();
      _equipped.clear();
      _spent = 0;
    }
    _loaded = true;
    _loading = false;
    notifyListeners();
  }

  /// Перечитать данные текущего профиля с диска (после импорта/смены профиля).
  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  /// Данные для экспорта: покупки, наряд и потраченные звёзды.
  Map<String, dynamic> exportData() => {
        'owned': _owned.toList(growable: false),
        'equipped': {
          for (final entry in _equipped.entries)
            entry.key.key: entry.value,
        },
        'spent': _spent,
      };

  /// Восстановить магазин из импортированной карты.
  ///
  /// Некорректные записи пропускаются, чтобы мусор из буфера обмена
  /// не ломал приложение.
  Future<void> importData(Map<String, dynamic> data) async {
    _owned.clear();
    _equipped.clear();
    _spent = 0;
    final owned = data['owned'];
    if (owned is List) {
      for (final id in owned) {
        if (id is String && accessoryById(id) != null) _owned.add(id);
      }
    }
    final equipped = data['equipped'];
    if (equipped is Map) {
      equipped.forEach((key, value) {
        if (key is! String || value is! String) return;
        final slot = AccessorySlot.fromKey(key);
        if (slot == null) return;
        if (_owned.contains(value)) _equipped[slot] = value;
      });
    }
    final spent = data['spent'];
    if (spent is num) _spent = spent.toInt();
    _loaded = true;
    notifyListeners();
    await _persist();
  }

  /// Сбросить покупки и наряд (для отладки/родительского режима).
  Future<void> reset() async {
    _owned.clear();
    _equipped.clear();
    _spent = 0;
    _loaded = true;
    notifyListeners();
    await _persist();
  }

  /// Ленивая загрузка: данные подтягиваются при первом обращении, поэтому
  /// сервис работает и без явной инициализации в `main()`.
  void _ensureLoaded() {
    if (_loaded || _loading) return;
    unawaited(load());
  }

  void _onProfileChanged() {
    unawaited(reload());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(exportData()));
    } catch (_) {
      // Игнорируем ошибки записи, чтобы не мешать игре.
    }
  }
}
