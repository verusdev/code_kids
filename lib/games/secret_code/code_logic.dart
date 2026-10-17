/// Чистые функции кодирования и шифрования для игры «Секретный код».
///
/// Файл не зависит от Flutter: его можно юнит-тестить и использовать в
/// утилите `tool/level_check.dart` для самопроверки уровней.
/// Все функции детерминированы: один и тот же вход всегда даёт один выход.
library;

/// Русский алфавит для шифров (33 буквы, «ё» — после «е»).
const String kRuAlphabet = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';

/// Двоичная запись числа (например, 5 → «101»).
String binEncode(int n) => n.toRadixString(2);

/// Число из двоичной строки (например, «101» → 5).
int binDecode(String bits) => int.parse(bits, radix: 2);

/// Шифр Цезаря: сдвиг каждой буквы на [shift] позиций вправо
/// (отрицательный сдвиг — влево). Буквы вне алфавита не меняются.
String caesarEncode(String word, int shift) {
  final buffer = StringBuffer();
  for (final rune in word.runes) {
    final ch = String.fromCharCode(rune);
    final index = kRuAlphabet.indexOf(ch);
    if (index < 0) {
      buffer.write(ch);
      continue;
    }
    final moved = (index + shift) % kRuAlphabet.length;
    buffer.write(kRuAlphabet[(moved + kRuAlphabet.length) % kRuAlphabet.length]);
  }
  return buffer.toString();
}

/// Обратный сдвиг: расшифровка слова, зашифрованного Цезарем.
String caesarDecode(String word, int shift) => caesarEncode(word, -shift);

/// Кодирует слово номерами букв: «КОТ» → «12 16 20» («а» = 1, … «я» = 33).
String digitEncode(String word) {
  return word
      .split('')
      .map((ch) => '${kRuAlphabet.indexOf(ch) + 1}')
      .join(' ');
}

/// Расшифровывает цифровой код: «12 16 20» → «КОТ».
String digitDecode(String digits) {
  return digits
      .split(' ')
      .map((code) => kRuAlphabet[int.parse(code) - 1])
      .join();
}
