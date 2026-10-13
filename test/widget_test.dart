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
}
