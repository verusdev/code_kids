import 'dart:convert';

import 'package:code_kids/python/python_interpreter.dart';
import 'package:code_kids/services/profile_service.dart';
import 'package:code_kids/services/turtle_gallery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Пауза: id рисунков строятся из «микросекунд» `DateTime.now()`, а на
/// Windows часы обновляются крупными шагами — без паузы id могут совпасть.
Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 20));

const Profile _defaultProfile = Profile(id: 'default', name: 'Друг', emoji: '🧒');
const Profile _kidProfile = Profile(id: 'kid2', name: 'Маша', emoji: '👧');

TurtleGalleryService get gallery => TurtleGalleryService.instance;

Future<void> seedProfiles(
  List<Profile> list, {
  String currentId = 'default',
}) async {
  SharedPreferences.setMockInitialValues({
    'flutter.code_kids_profiles_v1': jsonEncode({
      'profiles': [for (final p in list) p.toJson()],
      'currentId': currentId,
    }),
  });
  await ProfileService.instance.load();
}

List<TurtleSegment> _segments() => [
      TurtleSegment(0, 0, 10, 0),
      TurtleSegment(10, 0, 10, 10),
    ];

void main() {
  setUp(() async {
    await seedProfiles([_defaultProfile]);
    await gallery.load();
  });

  group('TurtleDrawing — сериализация', () {
    test('toJson/fromJson сохраняют отрезки', () {
      final drawing = TurtleDrawing(
        id: 'd1',
        name: 'Домик',
        createdAt: 1000,
        segments: _segments(),
      );
      final restored = TurtleDrawing.fromJson(drawing.toJson())!;

      expect(restored.id, 'd1');
      expect(restored.name, 'Домик');
      expect(restored.createdAt, 1000);
      expect(restored.segments, hasLength(2));
      expect(restored.segments.first.x2, 10);
      expect(restored.segments.last.y2, 10);
    });

    test('повреждённые записи отбрасываются', () {
      expect(TurtleDrawing.fromJson(const {}), isNull);
      expect(
        TurtleDrawing.fromJson(const {'id': '', 'name': 'x', 'createdAt': 1, 'segments': []}),
        isNull,
      );
      expect(
        TurtleDrawing.fromJson(const {'id': 'd', 'name': 'x', 'createdAt': 'bad', 'segments': []}),
        isNull,
      );
      expect(
        TurtleDrawing.fromJson(const {'id': 'd', 'name': 'x', 'createdAt': 1, 'segments': 'no'}),
        isNull,
      );
    });

    test('некорректные отрезки внутри записи пропускаются', () {
      final drawing = TurtleDrawing.fromJson(const {
        'id': 'd',
        'name': 'x',
        'createdAt': 1,
        'segments': [
          ['a', 'b', 'c', 'd'],
          [1, 2, 3, 4],
          [5, 6],
        ],
      })!;
      expect(drawing.segments, hasLength(1));
      expect(drawing.segments.single.x1, 1);
    });
  });

  group('галерея', () {
    test('add: новый рисунок идёт первым, имя обрезается', () async {
      await gallery.add('  Домик  ', _segments());
      expect(gallery.drawings, hasLength(1));
      expect(gallery.drawings.first.name, 'Домик');
      expect(gallery.drawings.first.id, isNotEmpty);
      expect(gallery.drawings.first.segments, hasLength(2));
    });

    test('add: пустое имя становится «Рисунок»', () async {
      await gallery.add('   ', _segments());
      expect(gallery.drawings.first.name, 'Рисунок');
    });

    test('add сохраняет рисунки на диск (перечитываются через load)',
        () async {
      await gallery.add('Спираль', _segments());
      await gallery.load();
      expect(gallery.drawings, hasLength(1));
      expect(gallery.drawings.first.name, 'Спираль');
    });

    test('remove удаляет нужный рисунок по id', () async {
      await gallery.add('Первый', _segments());
      await _tick();
      await gallery.add('Второй', _segments());
      final secondId = gallery.drawings.first.id;

      await gallery.remove(secondId);

      expect(gallery.drawings, hasLength(1));
      expect(gallery.drawings.single.name, 'Первый');
      // Повторное удаление ничего не делает.
      await gallery.remove(secondId);
      expect(gallery.drawings, hasLength(1));
    });

    test('clear удаляет все рисунки', () async {
      await gallery.add('A', _segments());
      await gallery.add('B', _segments());
      await gallery.clear();
      expect(gallery.drawings, isEmpty);
      await gallery.load();
      expect(gallery.drawings, isEmpty);
    });

    test('хранится не больше 30 рисунков — старые вытесняются', () async {
      for (var i = 0; i < 35; i++) {
        await gallery.add('D$i', _segments());
      }

      expect(gallery.drawings, hasLength(TurtleGalleryService.maxDrawings));
      expect(gallery.drawings.first.name, 'D34'); // новый — впереди
      expect(gallery.drawings.last.name, 'D5'); // самые старые вытеснены
      expect(gallery.drawings.any((d) => d.name == 'D0'), isFalse);
    });

    test('повреждённое хранилище не роняет load', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('code_kids_turtle_gallery_v1::default', 'не json{');
      await gallery.load();
      expect(gallery.drawings, isEmpty);
    });
  });

  group('экспорт / импорт', () {
    test('exportData → importData восстанавливает рисунки', () async {
      await gallery.add('Квадрат', _segments());
      final data = gallery.exportData();

      await gallery.clear();
      expect(gallery.drawings, isEmpty);

      await gallery.importData(data);
      expect(gallery.drawings, hasLength(1));
      expect(gallery.drawings.first.name, 'Квадрат');
      expect(gallery.drawings.first.segments, hasLength(2));
    });

    test('импорт мусора пропускает плохие записи и применяет лимит', () async {
      final many = [
        for (var i = 0; i < 40; i++)
          TurtleDrawing(
            id: 'd$i',
            name: 'R$i',
            createdAt: i,
            segments: _segments(),
          ).toJson(),
        'мусор',
        <String, dynamic>{'id': 'bad'},
      ];
      await gallery.importData({'drawings': many});

      expect(gallery.drawings, hasLength(TurtleGalleryService.maxDrawings));
      expect(gallery.drawings.first.name, 'R0');
    });

    test('импорт без ключа drawings очищает галерею', () async {
      await gallery.add('X', _segments());
      await gallery.importData(const {});
      expect(gallery.drawings, isEmpty);
    });
  });

  group('галерея — per-profile', () {
    test('рисунки хранятся отдельно для каждого профиля', () async {
      // Оба профиля уже есть; стартуем с «Друга» (без стирания хранилища).
      await seedProfiles([_defaultProfile, _kidProfile]);
      await gallery.load();

      await gallery.add('Рисунок Друга', _segments());
      expect(gallery.drawings, hasLength(1));

      // Профиль Маши видит пустую галерею.
      await ProfileService.instance.switchTo('kid2');
      await gallery.load();
      expect(gallery.drawings, isEmpty);

      await gallery.add('Рисунок Маши', _segments());
      expect(gallery.drawings.single.name, 'Рисунок Маши');

      // Возвращаемся к «Другу» — его рисунок на месте.
      await ProfileService.instance.switchTo('default');
      await gallery.load();
      expect(gallery.drawings, hasLength(1));
      expect(gallery.drawings.single.name, 'Рисунок Друга');
    });
  });
}
