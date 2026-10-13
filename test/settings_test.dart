import 'package:code_kids/screens/settings_screen.dart';
import 'package:code_kids/services/settings_service.dart';
import 'package:code_kids/services/sound_service.dart';
import 'package:code_kids/services/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final settings = SettingsService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.reset();
  });

  group('настройки', () {
    test('по умолчанию звук и озвучка включены', () {
      expect(settings.soundEnabled, isTrue);
      expect(settings.speechEnabled, isTrue);
    });

    test('значения сохраняются и загружаются', () async {
      await settings.setSound(false);
      await settings.setSpeech(false);
      expect(settings.soundEnabled, isFalse);
      expect(settings.speechEnabled, isFalse);

      // Сбрасываем в памяти и читаем из хранилища заново.
      SharedPreferences.setMockInitialValues({
        'flutter.code_kids_settings_v1':
            '{"sound":false,"speech":true}',
      });
      await settings.load();
      expect(settings.soundEnabled, isFalse);
      expect(settings.speechEnabled, isTrue);
    });

    test('при выключенном звуке методы SoundService не падают', () async {
      await settings.setSound(false);
      await SoundService.tap();
      await SoundService.win();
      await SoundService.wrong();
    });

    test('при выключенной озвучке speak ничего не делает', () async {
      await settings.setSpeech(false);
      await SpeechService.instance.speak('проверка');
      expect(settings.speechEnabled, isFalse);
    });
  });

  group('экран настроек', () {
    testWidgets('показывает переключатели и переключает звук', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Звуки'), findsOneWidget);
      expect(find.text('Озвучка'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));

      // Оба включены по умолчанию.
      expect(find.text('Включено'), findsNWidgets(2));

      // Выключаем звук.
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(settings.soundEnabled, isFalse);
      expect(find.text('Выключено'), findsOneWidget);
    });
  });
}
