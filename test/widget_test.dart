import 'package:code_kids/main.dart';
import 'package:code_kids/services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Главный экран показывает название и первую игру',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CodeKidsApp());
    await tester.pumpAndSettle();

    expect(find.text('Код-Квест'), findsOneWidget);
    expect(find.text('Робот-Лабиринт'), findsOneWidget);
  });

  testWidgets('Раздел системного мышления виден на главном экране',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CodeKidsApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('🧩 Системное мышление'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('🧩 Системное мышление'), findsOneWidget);
    expect(find.text('Части и целое'), findsOneWidget);
  });

  test('Первый уровень открыт, второй — закрыт по умолчанию', () {
    final progress = ProgressService.instance;
    expect(progress.isUnlocked('maze', 0), isTrue);
    expect(progress.isUnlocked('maze', 1), isFalse);
  });

  testWidgets('в футере есть входы в «Наряды» и «Наклейки», есть «Песочница»',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CodeKidsApp());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Песочница'),
      260,
      scrollable: scrollable,
    );
    expect(find.text('Песочница'), findsOneWidget);
    expect(find.text('Пиши любой код и запускай — без заданий!'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Наряды'),
      260,
      scrollable: scrollable,
    );
    expect(find.text('Наряды'), findsOneWidget);
    expect(find.text('Наклейки'), findsOneWidget);
    expect(find.text('Родителям'), findsOneWidget);
  });

  testWidgets('из футера открывается магазин нарядов', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CodeKidsApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Наряды'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Наряды'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Наряды'));
    await tester.pumpAndSettle();

    expect(find.text('🛒 Наряды'), findsOneWidget);
    expect(find.text('У тебя: 0 ⭐'), findsOneWidget);
  });
}
