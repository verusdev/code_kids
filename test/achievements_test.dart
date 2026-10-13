import 'package:code_kids/achievements/achievements.dart';
import 'package:code_kids/models/achievement.dart';
import 'package:code_kids/screens/achievements_screen.dart';
import 'package:code_kids/services/achievements_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Achievement _byId(String id) => kAchievements.firstWhere((a) => a.id == id);

void main() {
  group('условия достижений', () {
    test('на пустом прогрессе медалей нет', () {
      const snap = ProgressSnapshot({});
      expect(kAchievements.where((a) => a.isUnlocked(snap)), isEmpty);
    });

    test('первый пройденный уровень даёт «Первый шаг» и «Три из трёх»', () {
      const snap = ProgressSnapshot({
        'maze': [3],
      });
      expect(_byId('first_step').isUnlocked(snap), isTrue);
      expect(_byId('three_stars').isUnlocked(snap), isTrue);
      expect(_byId('star_10').isUnlocked(snap), isFalse);
      expect(_byId('robot').isUnlocked(snap), isFalse);
    });

    test('звёзды считаются по всем играм', () {
      final snap = ProgressSnapshot({
        'maze': List.filled(10, 3),
        'python': List.filled(5, 3),
      });
      expect(snap.allStars, 45);
      expect(snap.allPassed, 15);
      expect(snap.allPerfect, 15);
      expect(_byId('star_30').isUnlocked(snap), isTrue);
      expect(_byId('star_60').isUnlocked(snap), isFalse);
      expect(_byId('pythonist').isUnlocked(snap), isTrue);
      expect(_byId('robot').isUnlocked(snap), isTrue);
    });

    test('«Любознательный» и «Везде побывал» зависят от числа игр', () {
      final three = {for (final id in kAllGameIds.take(3)) id: const [1]};
      expect(_byId('explorer').isUnlocked(ProgressSnapshot(three)), isFalse);
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(three)), isFalse);

      final five = {for (final id in kAllGameIds.take(5)) id: const [1]};
      expect(_byId('explorer').isUnlocked(ProgressSnapshot(five)), isTrue);
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(five)), isFalse);

      final all = {for (final id in kAllGameIds) id: const [1]};
      expect(_byId('master_all').isUnlocked(ProgressSnapshot(all)), isTrue);
    });

    test('идентификаторы и тексты медалей заполнены и уникальны', () {
      final ids = kAchievements.map((a) => a.id).toSet();
      expect(ids.length, kAchievements.length);
      for (final a in kAchievements) {
        expect(a.title.trim(), isNotEmpty, reason: a.id);
        expect(a.description.trim(), isNotEmpty, reason: a.id);
        expect(a.emoji.trim(), isNotEmpty, reason: a.id);
      }
    });
  });

  group('экран достижений', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.reset();
    });

    testWidgets('показывает заголовок, счётчик и медали', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('🏅 Достижения'), findsOneWidget);
      expect(find.text('Открыто медалей: 0 из ${kAchievements.length}'),
          findsOneWidget);
      expect(find.text('Первый шаг'), findsOneWidget);
      expect(find.text('Питонист'), findsOneWidget);
      // На пустом прогрессе медали закрыты — показываем замки.
      expect(find.text('🔒'), findsWidgets);
    });
  });

  group('вручение медалей', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AchievementsService.instance.reset();
    });

    test('takeNewlyUnlocked выдаёт новую медаль ровно один раз', () async {
      const snap = ProgressSnapshot({
        'maze': [3],
      });
      final first = AchievementsService.instance.takeNewlyUnlocked(snap);
      expect(first.map((a) => a.id), contains('first_step'));
      final second = AchievementsService.instance.takeNewlyUnlocked(snap);
      expect(second, isEmpty);
    });
  });
}
