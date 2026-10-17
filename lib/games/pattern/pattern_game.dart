import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Уровень игры «Найди закономерность»: один вопрос с пропуском в конце.
class PatternLevel {
  const PatternLevel({
    required this.sequence,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Видимые элементы ряда (без пропуска).
  final List<String> sequence;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

final List<PatternLevel> _patternLevels = [
  const PatternLevel(
    sequence: ['🔴', '🔵', '🔴', '🔵'],
    options: ['🟢', '🔴', '🔵'],
    correctIndex: 1,
    explanation: 'Красный и синий чередуются: 🔴 🔵 🔴 🔵 → 🔴',
  ),
  const PatternLevel(
    sequence: ['🐶', '🐱', '🐶', '🐱', '🐶'],
    options: ['🐭', '🐶', '🐱'],
    correctIndex: 2,
    explanation: 'Собачка и котик по очереди: 🐶 🐱 🐶 🐱 🐶 → 🐱',
  ),
  const PatternLevel(
    sequence: ['⬆️', '➡️', '⬇️', '⬅️', '⬆️', '➡️'],
    options: ['⬅️', '⬇️', '⬆️'],
    correctIndex: 1,
    explanation: 'Стрелки идут по кругу: ⬆️ ➡️ ⬇️ ⬅️ и снова.',
  ),
  const PatternLevel(
    sequence: ['1️⃣', '2️⃣', '3️⃣', '1️⃣', '2️⃣'],
    options: ['2️⃣', '4️⃣', '3️⃣'],
    correctIndex: 2,
    explanation: 'Числа повторяются: 1 2 3 1 2 → 3',
  ),
  const PatternLevel(
    sequence: ['🔵', '🔵🔵', '🔵🔵🔵'],
    options: ['🔵🔵🔵🔵', '🔵🔵', '🔵'],
    correctIndex: 0,
    explanation: 'Каждый раз синих кружков на один больше.',
  ),
  const PatternLevel(
    sequence: ['🍎', '🍌', '🍇', '🍎', '🍌'],
    options: ['🍇', '🍎', '🍌'],
    correctIndex: 0,
    explanation: 'Фрукты идут по кругу: 🍎 🍌 🍇 и снова.',
  ),
  const PatternLevel(
    sequence: ['🌟', '🌙', '☀️', '🌟', '🌙', '☀️', '🌟'],
    options: ['🌙', '☀️', '🌟'],
    correctIndex: 0,
    explanation: 'Небо меняется по кругу: 🌟 🌙 ☀️ и снова → 🌙',
  ),
  const PatternLevel(
    sequence: ['🔴', '🔴', '🔵', '🔴', '🔴', '🔵', '🔴', '🔴'],
    options: ['🔵', '🔴', '🟢'],
    correctIndex: 0,
    explanation: 'Два красных, один синий — и снова: 🔴 🔴 🔵 → 🔵',
  ),
  const PatternLevel(
    sequence: ['2️⃣', '4️⃣', '6️⃣', '8️⃣'],
    options: ['🔟', '9️⃣', '8️⃣'],
    correctIndex: 0,
    explanation: 'Числа растут через два: 2, 4, 6, 8 → 10',
  ),
  const PatternLevel(
    sequence: ['1️⃣', '1️⃣2️⃣', '1️⃣2️⃣3️⃣'],
    options: ['1️⃣2️⃣3️⃣4️⃣', '1️⃣2️⃣3️⃣', '1️⃣2️⃣'],
    correctIndex: 0,
    explanation: 'С каждым шагом добавляется новое число: 1 → 12 → 123 → 1234',
  ),
  const PatternLevel(
    sequence: ['🟢', '🟢', '🔺', '🔺', '🟢', '🟢', '🔺', '🔺', '🟢'],
    options: ['🔺', '🟢', '🟡'],
    correctIndex: 1,
    explanation:
        'Два зелёных кружка, потом два треугольника — и снова: '
        '🟢 🟢 🔺 🔺 → 🟢',
  ),
  const PatternLevel(
    sequence: ['🔴', '🔵', '🟥', '🟦', '🔴', '🔵', '🟥'],
    options: ['🟦', '🔴', '🟥'],
    correctIndex: 0,
    explanation:
        'Меняются сразу и цвет, и форма: круги 🔴 🔵, потом квадраты 🟥 🟦. '
        'Дальше — синий квадрат 🟦.',
  ),
  const PatternLevel(
    sequence: ['2', '4', '7', '11'],
    options: ['16', '15', '17'],
    correctIndex: 0,
    explanation:
        'Каждый раз прибавляем на один больше: +2, +3, +4, значит дальше '
        '+5: 11 → 16',
  ),
  const PatternLevel(
    sequence: ['1', '2', '4', '5', '10'],
    options: ['20', '11', '12'],
    correctIndex: 1,
    explanation:
        'Действия чередуются: +1, потом ×2, и снова. 1+1=2, 2×2=4, 4+1=5, '
        '5×2=10 → 10+1=11',
  ),
  const PatternLevel(
    sequence: ['А1', 'Б2', 'В3', 'Г4'],
    options: ['Д5', 'Д4', 'Е5'],
    correctIndex: 0,
    explanation: 'И буква, и цифра растут на один: А1, Б2, В3, Г4 → Д5',
  ),
  const PatternLevel(
    sequence: ['🔴', '🔵', '🔵', '🔴', '🔵', '🔵', '🔴', '🔵', '🔵'],
    options: ['🔴', '🔵', '🟣'],
    correctIndex: 0,
    explanation:
        'Группы по три: красный и два синих. Три группы закончились, начинается новая — с красного.',
  ),
  const PatternLevel(
    sequence: ['⬆️', '⬆️', '➡️', '➡️', '⬇️', '⬇️', '⬅️', '⬅️'],
    options: ['⬇️', '⬆️', '➡️'],
    correctIndex: 1,
    explanation:
        'Каждая стрелка идёт два раза по кругу: вверх, вправо, вниз, влево. Два «влево» закончились — снова вверх.',
  ),
  const PatternLevel(
    sequence: ['🐱', '🐶', '🐶', '🐱', '🐶', '🐶', '🐱'],
    options: ['🐶', '🐱', '🐰'],
    correctIndex: 0,
    explanation:
        'После котика всегда идут две собачки, а потом снова котик. Значит, дальше собачка.',
  ),
  const PatternLevel(
    sequence: ['5', '8', '7', '10', '9', '12'],
    options: ['11', '10', '13'],
    correctIndex: 0,
    explanation:
        'Действия чередуются: плюс три, потом минус один. 5+3=8, 8−1=7, 7+3=10, 10−1=9, 9+3=12. Дальше минус один: 11.',
  ),
  const PatternLevel(
    sequence: ['1', '3', '2', '4', '3', '5', '4'],
    options: ['6', '5', '7'],
    correctIndex: 0,
    explanation:
        'Чередуются плюс два и минус один. Последнее действие было «минус один» (5−1=4), значит теперь плюс два: 4+2=6.',
  ),
  const PatternLevel(
    sequence: ['🟦', '🟥', '🟦', '🟦', '🟥', '🟦', '🟦', '🟦', '🟥'],
    options: ['🟦', '🟥', '🟧'],
    correctIndex: 0,
    explanation:
        'Между красными квадратами синих всё больше: один, два, три. Красный закончился — начинаются синие.',
  ),
  const PatternLevel(
    sequence: ['🌞', '🌧️', '🌧️', '🌞', '🌧️', '🌧️', '🌞', '🌧️', '🌧️'],
    options: ['🌞', '🌧️', '🌈'],
    correctIndex: 0,
    explanation:
        'После двух дождей всегда выходит солнце. Последний дождик закончился — будет солнце.',
  ),
  const PatternLevel(
    sequence: ['✏️', '✏️', '🖊️', '✏️', '✏️', '✏️', '🖊️'],
    options: ['✏️', '🖊️', '📐'],
    correctIndex: 0,
    explanation:
        'Карандашей между ручками всё больше: два, потом три. После ручки начинается новая группа — четыре карандаша.',
  ),
  const PatternLevel(
    sequence: ['🚗', '🚗', '🚕', '🚗', '🚗', '🚗', '🚕'],
    options: ['🚗', '🚕', '🚌'],
    correctIndex: 0,
    explanation:
        'Машин между такси становится больше: сначала две, потом три. После такси снова идут машины.',
  ),
  const PatternLevel(
    sequence: ['5', '6', '4', '7', '3', '8'],
    options: ['2', '3', '1'],
    correctIndex: 0,
    explanation:
        'Прибавления и убавления растут по очереди: +1, −2, +3, −4, +5. 5+1=6, 6−2=4, 4+3=7, 7−4=3, 3+5=8. Дальше минус шесть: 8−6=2.',
  ),
  const PatternLevel(
    sequence: ['🐣', '🐤', '🐥', '🐣', '🐤'],
    options: ['🐥', '🐣', '🐔'],
    correctIndex: 0,
    explanation:
        'Птенчики растут по кругу: яичко, маленький птенчик, большой птенчик. После маленького птенчика будет большой.',
  ),
  const PatternLevel(
    sequence: ['А', 'В', 'Д', 'Ж'],
    options: ['И', 'К', 'Л'],
    correctIndex: 0,
    explanation:
        'Буквы идут через одну: А, (Б), В, (Г), Д, (Е), Ж, (З) — следующая буква И.',
  ),
  const PatternLevel(
    sequence: ['🍊', '🍊', '🍋', '🍊', '🍊', '🍊', '🍋'],
    options: ['🍊', '🍋', '🥬'],
    correctIndex: 0,
    explanation:
        'Апельсинов между лимонами всё больше: два, потом три. После лимона начинается новая группа апельсинов.',
  ),
  const PatternLevel(
    sequence: ['1', '2', '4', '7', '11'],
    options: ['16', '15', '12'],
    correctIndex: 0,
    explanation:
        'Прибавляем всё больше: сначала +1, потом +2, +3 и +4. Дальше +5: 11+5=16.',
  ),
  const PatternLevel(
    sequence: ['А1', 'Б3', 'В5', 'Г7'],
    options: ['Д9', 'Д8', 'Е9'],
    correctIndex: 0,
    explanation:
        'Буква идёт по алфавиту, а число каждый раз растёт на два: Г7 + 2 = Д9.',
  ),
];

/// Уровни игры (открыты для автотестов).
List<PatternLevel> get patternLevels => _patternLevels;

/// Игра «Найди закономерность»: ребёнок выбирает, что продолжит ряд.
class PatternGame extends StatefulWidget {
  const PatternGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<PatternGame> createState() => _PatternGameState();
}

class _PatternGameState extends State<PatternGame> {
  late PatternLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  String _message = 'Что должно идти дальше?';

  static const GameInfo _game = GameInfo(
    id: 'pattern',
    title: 'Найди закономерность',
    subtitle: '',
    emoji: '🔁',
    levelCount: 30,
  );

  @override
  void initState() {
    super.initState();
    _level = _patternLevels[widget.levelIndex % _patternLevels.length];
  }

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _message = 'Что должно идти дальше?';
    });
  }

  void _choose(int index) {
    if (_won) return;
    if (index == _level.correctIndex) {
      final stars = _mistakes == 0
          ? 3
          : (_mistakes == 1 ? 2 : 1);
      setState(() {
        _won = true;
        _message = _level.explanation;
      });
      widget.onFinished(stars);
    } else {
      setState(() {
        _mistakes++;
        _wrongIndex = index;
        _message = 'Почти! Посмотри на ряд ещё раз 👀';
      });
    }
  }

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
                  child: HintBar(text: _message, color: AppTheme.orange),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _sequenceRow(),
                        const SizedBox(height: 28),
                        const Text(
                          'Выбери, что дальше:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _level.options.length; i++)
                              _optionCard(i),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1),
                maxLevelIndex: _patternLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sequenceRow() {
    final items = <Widget>[];
    for (final s in _level.sequence) {
      items.add(_card(s));
    }
    items.add(
      Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.orange, width: 3),
        ),
        alignment: Alignment.center,
        child: const Text('❓', style: TextStyle(fontSize: 38)),
      ),
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: items,
    );
  }

  Widget _card(String emoji) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(emoji, style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }

  Widget _optionCard(int index) {
    final isWrong = _wrongIndex == index;
    return GestureDetector(
      onTap: () => _choose(index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isWrong
              ? Colors.red.shade50
              : (index == _level.correctIndex && _won
                  ? Colors.green.shade50
                  : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWrong
                ? Colors.red
                : (index == _level.correctIndex && _won
                    ? Colors.green
                    : AppTheme.orange.withValues(alpha: 0.5)),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _level.options[index],
              style: const TextStyle(fontSize: 44),
            ),
          ),
        ),
      ),
    );
  }
}
