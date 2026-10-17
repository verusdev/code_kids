import 'package:code_kids/achievements/achievements.dart';
import 'package:code_kids/models/achievement.dart';
import 'package:code_kids/screens/stickers_screen.dart';
import 'package:code_kids/services/daily_service.dart';
import 'package:code_kids/services/mascot_service.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:code_kids/stickers/stickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Sticker sticker(String id) => kStickers.firstWhere((s) => s.id == id);

/// Снимок прогресса, на котором открыты ВСЕ наклейки.
ProgressSnapshot _everythingUnlocked() => ProgressSnapshot(
      {for (final id in kAllGameIds) id: List.filled(20, 3)},
      streak: 10,
      achievementsUnlocked: 20,
    );

void main() {
  group('условия наклеек', () {
    test('на пустом прогрессе не открыто ни одной наклейки', () {
      const snap = ProgressSnapshot({});
      expect(unlockedStickerCount(snap), 0);
      expect(kStickers.where((s) => s.isUnlocked(snap)), isEmpty);
    });

    test('один пройденный уровень открывает только «Первые шаги»', () {
      const snap = ProgressSnapshot({
        'maze': [3],
      });
      final unlocked = kStickers.where((s) => s.isUnlocked(snap)).toList();
      expect(unlocked.map((s) => s.id), ['first_step']);
      expect(unlockedStickerCount(snap), 1);
    });

    test('на максимальном прогрессе открыты все наклейки', () {
      expect(unlockedStickerCount(_everythingUnlocked()), kStickers.length);
    });

    test('порог звёзд строго на границе (9 → нет, 10 → да)', () {
      const nine = ProgressSnapshot({
        'maze': [3, 3, 3],
      });
      const ten = ProgressSnapshot({
        'maze': [3, 3, 3, 1],
      });
      expect(sticker('star_10').isUnlocked(nine), isFalse);
      expect(sticker('star_10').isUnlocked(ten), isTrue);
    });

    test('наклейки за конкретные игры требуют нужное число уровней', () {
      expect(
        sticker('maze_5').isUnlocked(const ProgressSnapshot({'maze': [1, 1, 1, 1]})),
        isFalse,
      );
      expect(
        sticker('maze_5').isUnlocked(const ProgressSnapshot({'maze': [1, 1, 1, 1, 1]})),
        isTrue,
      );
      // Уровни другой игры не считаются.
      expect(
        sticker('pixel_5').isUnlocked(const ProgressSnapshot({'maze': [1, 1, 1, 1, 1]})),
        isFalse,
      );
      // Python-наклейки считают только уроки Python.
      expect(
        sticker('python_3')
            .isUnlocked(const ProgressSnapshot({'python': [1, 1, 1]})),
        isTrue,
      );
    });

    test('серия дней открывает наклейки постоянства', () {
      expect(
        sticker('streak_3').isUnlocked(const ProgressSnapshot({}, streak: 2)),
        isFalse,
      );
      expect(
        sticker('streak_3').isUnlocked(const ProgressSnapshot({}, streak: 3)),
        isTrue,
      );
      expect(
        sticker('streak_7').isUnlocked(const ProgressSnapshot({}, streak: 6)),
        isFalse,
      );
      expect(
        sticker('streak_7').isUnlocked(const ProgressSnapshot({}, streak: 7)),
        isTrue,
      );
    });

    test('наклейка за медали зависит от числа открытых медалей', () {
      expect(
        sticker('medals_5')
            .isUnlocked(const ProgressSnapshot({}, achievementsUnlocked: 4)),
        isFalse,
      );
      expect(
        sticker('medals_5')
            .isUnlocked(const ProgressSnapshot({}, achievementsUnlocked: 5)),
        isTrue,
      );
    });

    test('«Путешественник» считает только игры с реальными звёздами', () {
      // Пять игр, но во всех нули — это не «начатые» игры.
      final zeros = {for (final id in kAllGameIds.take(5)) id: const [0]};
      expect(sticker('explorer').isUnlocked(ProgressSnapshot(zeros)), isFalse);

      final started = {for (final id in kAllGameIds.take(5)) id: const [1]};
      expect(sticker('explorer').isUnlocked(ProgressSnapshot(started)), isTrue);
    });

    test('прогресс не «отбирает» уже открытые наклейки (монотонность)', () {
      const small = ProgressSnapshot({
        'maze': [3],
      });
      final big = ProgressSnapshot(
        {'maze': List.filled(5, 3), 'pixel': List.filled(5, 3)},
        streak: 3,
      );

      expect(unlockedStickerCount(big),
          greaterThanOrEqualTo(unlockedStickerCount(small)));
      for (final s in kStickers) {
        if (s.isUnlocked(small)) {
          expect(s.isUnlocked(big), isTrue, reason: s.id);
        }
      }
    });

    test('идентификаторы и тексты наклеек заполнены и уникальны', () {
      final ids = kStickers.map((s) => s.id).toSet();
      expect(ids.length, kStickers.length);
      for (final s in kStickers) {
        expect(s.name.trim(), isNotEmpty, reason: s.id);
        expect(s.emoji.trim(), isNotEmpty, reason: s.id);
        expect(s.hint.trim(), isNotEmpty, reason: s.id);
      }
    });
  });

  group('экран наклеек', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.reset();
      await MascotService.instance.reset();
      await DailyService.instance.reset();
    });

    testWidgets('на пустом прогрессе показывает шапку и замки', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: StickersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('📖 Наклейки'), findsOneWidget);
      expect(find.text('Открыто: 0 из ${kStickers.length}'), findsOneWidget);
      expect(find.text('🔒'), findsNWidgets(kStickers.length));
      // Подсказки видны, пока наклейка закрыта.
      expect(find.text('Собери 10 звёзд'), findsOneWidget);
    });

    testWidgets('открытая наклейка показывается без замка', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Один пройденный уровень → открыта ровно одна наклейка.
      await ProgressService.instance.record('maze', 0, 3, 10);

      await tester.pumpWidget(const MaterialApp(home: StickersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Открыто: 1 из ${kStickers.length}'), findsOneWidget);
      expect(find.text('🔒'), findsNWidgets(kStickers.length - 1));
      expect(find.text('Открыта! 🎉'), findsOneWidget);
    });
  });
}
