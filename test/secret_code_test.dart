// Проверка игры «Секретный код»: структура 15 уровней, связь показанного
// задания с ответом через чистые функции кодирования (code_logic.dart)
// и юнит-тесты самих шифров (двоичный код, Цезарь, цифровая азбука).
import 'package:code_kids/games/secret_code/code_logic.dart';
import 'package:code_kids/games/secret_code/secret_code_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// Правильный ответ уровня, посчитанный чистыми функциями кодирования.
String expectedAnswer(CodeLevel level) => switch (level.type) {
      CodeType.binaryToNumber => '${binDecode(level.bits!.join())}',
      CodeType.numberToBinary => binEncode(level.number!),
      CodeType.caesarDecode => level.word!,
      CodeType.caesarEncode => caesarEncode(level.word!, level.shift!),
      CodeType.digitDecode => level.word!,
      CodeType.digitEncode => digitEncode(level.word!),
    };

/// Текст задания, как его строит игра (приватный геттер `_shownText`).
String shownText(CodeLevel level) => switch (level.type) {
      CodeType.binaryToNumber => level.bits!.join(),
      CodeType.numberToBinary => '${level.number}',
      CodeType.caesarDecode => caesarEncode(level.word!, level.shift!),
      CodeType.caesarEncode => level.word!,
      CodeType.digitDecode => digitEncode(level.word!),
      CodeType.digitEncode => level.word!,
    };

/// Проверяет, что показанный код действительно превращается в верный ответ:
/// для каждой операции кодирования своя обратная операция.
bool decodeShownGivesAnswer(CodeLevel level) {
  final answer = expectedAnswer(level);
  return switch (level.type) {
    CodeType.binaryToNumber =>
      '${binDecode(shownText(level))}' == answer,
    // Показано число, ответ — его двоичная запись: декодируем ответ.
    CodeType.numberToBinary => '${binDecode(answer)}' == shownText(level),
    CodeType.caesarDecode =>
      caesarDecode(shownText(level), level.shift!) == answer,
    CodeType.caesarEncode =>
      caesarEncode(shownText(level), level.shift!) == answer,
    CodeType.digitDecode => digitDecode(shownText(level)) == answer,
    CodeType.digitEncode => digitEncode(shownText(level)) == answer,
  };
}

void main() {
  group('Кодирование: двоичный код', () {
    test('binEncode / binDecode — прямая и обратная операция', () {
      expect(binEncode(5), '101');
      expect(binDecode('101'), 5);
      expect(binEncode(0), '0');
      expect(binEncode(31), '11111');
      for (var n = 0; n <= 31; n++) {
        expect(binDecode(binEncode(n)), n, reason: 'число $n');
      }
    });
  });

  group('Кодирование: шифр Цезаря', () {
    test('алфавит — 33 буквы, «ё» сразу после «е»', () {
      expect(kRuAlphabet.length, 33);
      expect(kRuAlphabet.indexOf('Ё'), kRuAlphabet.indexOf('Е') + 1);
    });

    test('сдвиг зацикливается (Я + 1 = А, А − 1 = Я)', () {
      expect(caesarEncode('Я', 1), 'А');
      expect(caesarEncode('А', -1), 'Я');
      expect(caesarEncode('КОТ', 0), 'КОТ');
    });

    test('латиница, цифры и пробелы не меняются', () {
      expect(caesarEncode('abc 123', 3), 'abc 123');
    });

    test('кодирование и декодирование со сдвигами 1..5 — туда и обратно', () {
      const words = ['КОТ', 'ЛИСА', 'ЗАЙКА', 'КОРОВА', 'ПРИВЕТ'];
      for (var shift = 1; shift <= 5; shift++) {
        for (final word in words) {
          final encoded = caesarEncode(word, shift);
          expect(caesarDecode(encoded, shift), word,
              reason: '$word, сдвиг $shift');
        }
      }
    });
  });

  group('Кодирование: цифровая азбука', () {
    test('digitEncode / digitDecode — прямая и обратная операция', () {
      expect(digitEncode('КОТ'), '12 16 20');
      expect(digitDecode('12 16 20'), 'КОТ');
      expect(digitEncode('ЛИСА'), '13 10 19 1');
      const words = ['КОТ', 'ДОМ', 'ЛИСА', 'ЗАЙКА', 'АЯ'];
      for (final word in words) {
        expect(digitDecode(digitEncode(word)), word, reason: word);
      }
    });
  });

  group('Уровни «Секретного кода»', () {
    test('в игре 15 уровней', () {
      expect(codeLevels.length, 15);
    });

    test('структура уровней заполнена корректно', () {
      for (var i = 0; i < codeLevels.length; i++) {
        final level = codeLevels[i];
        final n = i + 1;
        expect(level.options.length, greaterThanOrEqualTo(2),
            reason: 'уровень $n: мало вариантов');
        expect(
          level.correctIndex,
          inInclusiveRange(0, level.options.length - 1),
          reason: 'уровень $n: неверный correctIndex',
        );
        expect(level.hint, isNotEmpty, reason: 'уровень $n: пустая подсказка');
        expect(level.explanation, isNotEmpty,
            reason: 'уровень $n: пустое пояснение');

        switch (level.type) {
          case CodeType.binaryToNumber:
            expect(level.bits, isNotNull, reason: 'уровень $n: нет лампочек');
            expect(level.bits, isNotEmpty, reason: 'уровень $n: пустые лампочки');
            expect(level.bits!.every((b) => b == 0 || b == 1), isTrue,
                reason: 'уровень $n: лампочки не 0/1');
          case CodeType.numberToBinary:
            expect(level.number, isNotNull, reason: 'уровень $n: нет числа');
          case CodeType.caesarDecode:
          case CodeType.caesarEncode:
            expect(level.word, isNotNull, reason: 'уровень $n: нет слова');
            expect(level.shift, isNotNull, reason: 'уровень $n: нет сдвига');
          case CodeType.digitDecode:
          case CodeType.digitEncode:
            expect(level.word, isNotNull, reason: 'уровень $n: нет слова');
        }
      }
    });

    test('верный вариант — это правильный ответ на задание', () {
      for (var i = 0; i < codeLevels.length; i++) {
        final level = codeLevels[i];
        expect(level.options[level.correctIndex], expectedAnswer(level),
            reason: 'уровень ${i + 1}: верный вариант не совпадает '
                'с ответом кодирования');
      }
    });

    test('правильный ответ присутствует среди вариантов ровно один раз', () {
      for (var i = 0; i < codeLevels.length; i++) {
        final level = codeLevels[i];
        final answer = expectedAnswer(level);
        final count = level.options.where((o) => o == answer).length;
        expect(count, 1,
            reason: 'уровень ${i + 1}: «$answer» встречается $count раз');
      }
    });

    test('показанный код расшифровывается в верный вариант', () {
      for (var i = 0; i < codeLevels.length; i++) {
        final level = codeLevels[i];
        expect(decodeShownGivesAnswer(level), isTrue,
            reason: 'уровень ${i + 1}: обратное кодирование «${shownText(level)}» '
                'не даёт верный вариант «${level.options[level.correctIndex]}»');
      }
    });

    test('ответ не показан в задании напрямую', () {
      for (var i = 0; i < codeLevels.length; i++) {
        final level = codeLevels[i];
        expect(shownText(level) == level.options[level.correctIndex], isFalse,
            reason: 'уровень ${i + 1}: ответ виден прямо в задании');
      }
    });
  });
}
