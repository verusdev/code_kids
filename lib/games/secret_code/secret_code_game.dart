import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import 'code_logic.dart';

/// Тип задания в игре «Секретный код».
enum CodeType {
  /// Показаны лампочки двоичного числа — выбрать число.
  binaryToNumber,

  /// Показано число — выбрать его двоичный код.
  numberToBinary,

  /// Показано слово, зашифрованное Цезарем — выбрать расшифровку.
  caesarDecode,

  /// Показано слово — выбрать его шифр Цезаря со сдвигом.
  caesarEncode,

  /// Показан цифровой код (а=1, б=2, …) — выбрать слово.
  digitDecode,

  /// Показано слово — выбрать цифровой код.
  digitEncode,
}

/// Описание одного уровня игры «Секретный код».
///
/// Заполнение полей зависит от [type]:
///  * binaryToNumber — [bits];
///  * numberToBinary — [number];
///  * caesar* — [word] и [shift];
///  * digit* — [word].
class CodeLevel {
  const CodeLevel({
    required this.type,
    this.bits,
    this.number,
    this.word,
    this.shift,
    required this.options,
    required this.correctIndex,
    required this.hint,
    required this.explanation,
  });

  final CodeType type;
  final List<int>? bits;
  final int? number;
  final String? word;
  final int? shift;
  final List<String> options;
  final int correctIndex;
  final String hint;
  final String explanation;
}

final List<CodeLevel> _codeLevels = [
  // 1. Двоичные лампочки → число (до 7).
  const CodeLevel(
    type: CodeType.binaryToNumber,
    bits: [1, 0, 1],
    options: ['3', '5', '6', '7'],
    correctIndex: 1,
    hint: 'Левая лампочка — это 4, средняя — 2, правая — 1. Сложи горящие!',
    explanation: '101 — это 5: единица слева значит 4, и ещё одна единица — 1. '
        '4 + 1 = 5!',
  ),
  // 2. Число → двоичный код (до 7).
  CodeLevel(
    type: CodeType.numberToBinary,
    number: 6,
    options: ['100', '110', '111', '101'],
    correctIndex: 1,
    hint: '6 = 4 + 2: какие лампочки понадобятся?',
    explanation: '6 = 110: 4 + 2 = 6, поэтому горят две лампочки слева — '
        '«четвёрка» и «двойка».',
  ),
  // 3. Цифровой код → слово (3 буквы).
  CodeLevel(
    type: CodeType.digitDecode,
    word: 'КОТ',
    options: ['КОД', 'ДОМ', 'КОТ', 'ТОК'],
    correctIndex: 2,
    hint: '«К» — какая по счёту буква? Посчитай от «а».',
    explanation: 'КОТ — это 12, 16, 20: «К» — двенадцатая буква, '
        '«О» — шестнадцатая, «Т» — двадцатая.',
  ),
  // 4. Двоичные лампочки → число (до 15).
  CodeLevel(
    type: CodeType.binaryToNumber,
    bits: [1, 1, 0, 0],
    options: ['8', '10', '12', '14'],
    correctIndex: 2,
    hint: 'Слева самая большая лампочка — 8. Дальше — 4, 2 и 1.',
    explanation: '1100 — это 12: 8 + 4 = 12 — горят лампочки '
        '«восьмёрка» и «четвёрка».',
  ),
  // 5. Шифр Цезаря, сдвиг 1 (3 буквы).
  CodeLevel(
    type: CodeType.caesarDecode,
    word: 'ФОК',
    shift: 1,
    options: ['ФОК', 'ЛОК', 'ФОН', 'СОК'],
    correctIndex: 0,
    hint: 'Каждая буква сдвинулась на 1 вправо. Верни их на шаг назад!',
    explanation: 'Шифр Цезаря со сдвигом 1: чтобы прочитать, верни каждую '
        'букву на шаг влево. Х → Ф, П → О, Л → К. Получается ФОК.',
  ),
  // 6. Число → двоичный код (до 15).
  CodeLevel(
    type: CodeType.numberToBinary,
    number: 13,
    options: ['1100', '1011', '1101', '1110'],
    correctIndex: 2,
    hint: '13 = 8 + 4 + 1. Какие лампочки включить?',
    explanation: '13 = 1101: 8 + 4 + 1 = 13 — горят первая, вторая '
        'и последняя лампочки.',
  ),
  // 7. Слово → цифровой код (3 буквы).
  CodeLevel(
    type: CodeType.digitEncode,
    word: 'ДОМ',
    options: ['4 15 13', '5 16 14', '5 16 12', '5 15 14'],
    correctIndex: 1,
    hint: 'Найди каждую букву по счёту: «а» = 1, «б» = 2, …',
    explanation: 'ДОМ — это 5, 16, 14: «Д» — пятая буква, «О» — шестнадцатая, '
        '«М» — четырнадцатая.',
  ),
  // 8. Шифр Цезаря, сдвиг 2 (4 буквы).
  CodeLevel(
    type: CodeType.caesarDecode,
    word: 'ЛИСА',
    shift: 2,
    options: ['ЛИСА', 'МИША', 'ЛИНА', 'ЛЬВА'],
    correctIndex: 0,
    hint: 'Сдвиг на 2: каждую букву верни на два шага влево.',
    explanation: 'Сдвиг на 2: верни каждую букву на 2 шага влево. '
        'Н → Л, К → И, У → С, В → А. Получается ЛИСА.',
  ),
  // 9. Двоичные лампочки → число (до 31).
  CodeLevel(
    type: CodeType.binaryToNumber,
    bits: [1, 0, 1, 0, 1],
    options: ['19', '20', '21', '25'],
    correctIndex: 2,
    hint: 'Лампочки: 16, 8, 4, 2, 1. Сложи те, что горят.',
    explanation: '10101 — это 21: 16 + 4 + 1 = 21.',
  ),
  // 10. Слово → шифр Цезаря, сдвиг 3 (3 буквы).
  CodeLevel(
    type: CodeType.caesarEncode,
    word: 'КОТ',
    shift: 3,
    options: ['НСХ', 'НКУ', 'МСХ', 'НСГ'],
    correctIndex: 0,
    hint: 'Сдвинь каждую букву на 3 вправо: К → Л → М → Н.',
    explanation: 'Шифр Цезаря, сдвиг 3 вправо: К → Н, О → С, Т → Х. '
        'Получается НСХ.',
  ),
  // 11. Цифровой код → слово (4 буквы).
  CodeLevel(
    type: CodeType.digitDecode,
    word: 'ЛИСА',
    options: ['ЛИСА', 'ЛИНА', 'ЛЬВА', 'МУРА'],
    correctIndex: 0,
    hint: '13 — какая это буква? Считай от «а» = 1.',
    explanation: 'ЛИСА — это 13, 10, 19, 1: «Л» — тринадцатая буква, '
        '«И» — десятая, «С» — девятнадцатая, «А» — первая.',
  ),
  // 12. Шифр Цезаря, сдвиг 4 (5 букв).
  CodeLevel(
    type: CodeType.caesarDecode,
    word: 'ЗАЙКА',
    shift: 4,
    options: ['ЗАЙКА', 'ЗАЧЕМ', 'ЗЕМЛЯ', 'ЖАБА'],
    correctIndex: 0,
    hint: 'Сдвиг на 4: каждую букву верни на четыре шага влево.',
    explanation: 'Сдвиг на 4: Л → З, Д → А, Н → Й, О → К, Д → А. '
        'Получается ЗАЙКА.',
  ),
  // 13. Число → двоичный код (до 31).
  CodeLevel(
    type: CodeType.numberToBinary,
    number: 27,
    options: ['11000', '11010', '11011', '11111'],
    correctIndex: 2,
    hint: '27 = 16 + 8 + 2 + 1. Какие лампочки включить?',
    explanation: '27 = 11011: 16 + 8 + 2 + 1 = 27.',
  ),
  // 14. Двоичные лампочки → максимум (31).
  CodeLevel(
    type: CodeType.binaryToNumber,
    bits: [1, 1, 1, 1, 1],
    options: ['15', '27', '30', '31'],
    correctIndex: 3,
    hint: 'Горят все лампочки: 16 + 8 + 4 + 2 + 1. Сколько выйдет?',
    explanation: '11111 — это 31: 16 + 8 + 4 + 2 + 1 = 31 — '
        'горят все лампочки!',
  ),
  // 15. Финал: шифр Цезаря, сдвиг 5 (6 букв).
  CodeLevel(
    type: CodeType.caesarDecode,
    word: 'КОРОВА',
    shift: 5,
    options: ['КОРОВА', 'КОРОНА', 'КОШКА', 'ЛОШАДЬ'],
    correctIndex: 0,
    hint: 'Большое слово, но принцип тот же: сдвиг на 5 назад. Начни с «П».',
    explanation: 'Сдвиг на 5: П → К, У → О, Х → Р, У → О, Ж → В, Е → А. '
        'Получается КОРОВА.',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих арифметику).
List<CodeLevel> get codeLevels => _codeLevels;

/// Акцентный цвет игры (из общей палитры темы).
Color get _codeColor => AppTheme.gameColors['code'] ?? AppTheme.sky;

/// Игра «Секретный код»: двоичные числа, шифр Цезаря и цифровая азбука.
/// Учит основам кодирования: числа — это наборы «лампочек», а букву можно
/// спрятать, сдвинув или заменив номером.
class SecretCodeGame extends StatefulWidget {
  const SecretCodeGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<SecretCodeGame> createState() => _SecretCodeGameState();
}

class _SecretCodeGameState extends State<SecretCodeGame> {
  late CodeLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  bool _showWin = false;
  String _message = '';

  static const GameInfo _game = GameInfo(
    id: 'code',
    title: 'Секретный код',
    subtitle: '',
    emoji: '🔐',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _codeLevels[widget.levelIndex % _codeLevels.length];
    _message = _level.hint;
  }

  int get _stars => _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _showWin = false;
      _message = _level.hint;
    });
  }

  void _choose(int index) {
    if (_won) return;
    if (index == _level.correctIndex) {
      setState(() {
        _won = true;
        _message = _level.explanation;
      });
      widget.onFinished(_stars);
    } else {
      setState(() {
        _mistakes++;
        _wrongIndex = index;
        _message = 'Не совсем… Попробуй ещё раз 🙂';
      });
    }
  }

  /// Текст показываемого задания (что нужно расшифровать или закодировать).
  String get _shownText => switch (_level.type) {
        CodeType.binaryToNumber => '',
        CodeType.numberToBinary => '${_level.number}',
        CodeType.caesarDecode => caesarEncode(_level.word!, _level.shift!),
        CodeType.caesarEncode => _level.word!,
        CodeType.digitDecode => digitEncode(_level.word!),
        CodeType.digitEncode => _level.word!,
      };

  /// Вопрос уровня крупным шрифтом.
  String get _question => switch (_level.type) {
        CodeType.binaryToNumber => 'Какое число спрятано в лампочках?',
        CodeType.numberToBinary => 'Набери двоичный код числа:',
        CodeType.caesarDecode => 'Какое слово спряталось в шифре? '
            '(сдвиг на ${_level.shift})',
        CodeType.caesarEncode => 'Зашифруй слово (сдвиг на ${_level.shift}):',
        CodeType.digitDecode => 'Какое слово спряталось в цифрах? '
            '(а = 1, б = 2, …)',
        CodeType.digitEncode => 'Кодируй слово цифрами (а = 1, б = 2, …):',
      };

  /// Варианты-ответы для «число → код» показываются лампочками.
  bool get _optionsAreBulbs => _level.type == CodeType.numberToBinary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: _message, color: _codeColor),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          children: [
                            _questionCard(),
                            const SizedBox(height: 12),
                            _optionsGrid(),
                            if (_won) ...[
                              const SizedBox(height: 12),
                              KidButton(
                                label: 'Забрать звёзды ⭐',
                                icon: Icons.star_rounded,
                                color: AppTheme.yellow,
                                expand: true,
                                onPressed: () =>
                                    setState(() => _showWin = true),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showWin)
              WinOverlay(
                game: _game,
                stars: _stars,
                maxLevelIndex: _codeLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  /// Карточка с заданием: лампочки, число, шифр или цифровой код.
  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _codeColor.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _question,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_level.type == CodeType.binaryToNumber)
            _bulbRow(_level.bits!)
          else if (_level.type == CodeType.numberToBinary)
            Text(
              _shownText,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            )
          else if (_level.type == CodeType.caesarDecode)
            Text(
              _shownText,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: AppTheme.ink,
              ),
            )
          else if (_level.type == CodeType.digitDecode)
            Text(
              _shownText,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            )
          else
            Text(
              _shownText,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppTheme.ink,
              ),
            ),
        ],
      ),
    );
  }

  /// Ряд лампочек: 💡 — единица, ⚫ — ноль.
  Widget _bulbRow(List<int> bits) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final bit in bits)
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bit == 1
                  ? AppTheme.yellow.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              bit == 1 ? '💡' : '⚫',
              style: const TextStyle(fontSize: 30),
            ),
          ),
      ],
    );
  }

  /// Сетка вариантов ответа.
  Widget _optionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (var i = 0; i < _level.options.length; i++) _optionCard(i),
      ],
    );
  }

  Widget _optionCard(int index) {
    final isWrong = _wrongIndex == index;
    final isCorrect = index == _level.correctIndex && _won;
    final text = _level.options[index];
    return GestureDetector(
      onTap: _won ? null : () => _choose(index),
      child: Container(
        decoration: BoxDecoration(
          color: isWrong
              ? Colors.red.shade50
              : (isCorrect ? Colors.green.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWrong
                ? Colors.red
                : (isCorrect
                    ? Colors.green
                    : _codeColor.withValues(alpha: 0.35)),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child: _optionsAreBulbs
            ? _bulbRow(text.split('').map(int.parse).toList())
            : Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
      ),
    );
  }
}
