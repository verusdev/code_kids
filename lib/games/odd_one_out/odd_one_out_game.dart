import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Уровень игры «Лишний элемент».
class OddLevel {
  const OddLevel({
    required this.items,
    required this.oddIndex,
    required this.explanation,
  });

  final List<String> items;
  final int oddIndex;
  final String explanation;
}

final List<OddLevel> _oddLevels = [
  const OddLevel(
    items: ['🚗', '🍎', '🍌', '🍇'],
    oddIndex: 0,
    explanation: 'Машина — это транспорт, а яблоко, банан и виноград — фрукты.',
  ),
  const OddLevel(
    items: ['🐶', '🐱', '🌳', '🐰'],
    oddIndex: 2,
    explanation: 'Дерево — растение, а собака, кошка и заяц — животные.',
  ),
  const OddLevel(
    items: ['🔴', '⬛', '🔵', '🟢'],
    oddIndex: 1,
    explanation: 'Квадрат — не круглый, все остальные — круги.',
  ),
  const OddLevel(
    items: ['✈️', '🚗', '🏠', '🚂'],
    oddIndex: 2,
    explanation: 'Дом — здание, а самолёт, машина и поезд — транспорт.',
  ),
  const OddLevel(
    items: ['1️⃣', '2️⃣', '🍎', '3️⃣'],
    oddIndex: 2,
    explanation: 'Яблоко — не число, а 1, 2 и 3 — это числа.',
  ),
  const OddLevel(
    items: ['🎸', '⚽', '🏀', '🎾'],
    oddIndex: 0,
    explanation: 'Гитара — музыкальный инструмент, а остальные — мячи.',
  ),
  const OddLevel(
    items: ['🐝', '🦋', '🐞', '🐟'],
    oddIndex: 3,
    explanation:
        'Рыба живёт в воде, а пчела, бабочка и божья коровка — насекомые.',
  ),
  const OddLevel(
    items: ['🍎', '🥕', '🍐', '🍊'],
    oddIndex: 1,
    explanation: 'Морковка — овощ, а яблоко, груша и апельсин — фрукты.',
  ),
  const OddLevel(
    items: ['☀️', '🌙', '⭐', '🚗'],
    oddIndex: 3,
    explanation: 'Машина ездит по земле, а солнце, луна и звезда — на небе.',
  ),
  const OddLevel(
    items: ['👟', '🧢', '🧤', '🍰'],
    oddIndex: 3,
    explanation: 'Торт — это еда, а кроссовки, кепка и перчатки — одежда.',
  ),
  const OddLevel(
    items: ['2️⃣', '7️⃣', '4️⃣', '6️⃣'],
    oddIndex: 1,
    explanation: 'Число 7 нечётное, а 2, 4 и 6 — чётные числа.',
  ),
  const OddLevel(
    items: ['🔺', '🟥', '🟦', '🟪'],
    oddIndex: 0,
    explanation: 'У треугольника три стороны, а у квадратов — четыре.',
  ),
  const OddLevel(
    items: ['🦅', '🐦', '🦇', '🦉'],
    oddIndex: 2,
    explanation:
        'Летучая мышь — зверь, а не птица, хоть и умеет летать. '
        'Орёл, воробей и сова — птицы.',
  ),
  const OddLevel(
    items: ['✏️', '🥄', '🖍️', '🖌️'],
    oddIndex: 1,
    explanation:
        'Ложка нужна для еды, а карандаш, мелок и кисточка — для рисования.',
  ),
  const OddLevel(
    items: ['🌸', '🍁', '🌙', '❄️'],
    oddIndex: 2,
    explanation: 'Ночь — это часть суток, а весна, осень и зима — времена года.',
  ),
  const OddLevel(
    items: ['🐯', '🦁', '🐺', '🐮'],
    oddIndex: 3,
    explanation:
        'Тигр, лев и волк — хищники, они охотятся. А корова — травоядное животное.',
  ),
  const OddLevel(
    items: ['1️⃣', '3️⃣', '8️⃣', '5️⃣'],
    oddIndex: 2,
    explanation: 'Восемь — чётное число, а 1, 3 и 5 — нечётные.',
  ),
  const OddLevel(
    items: ['🦆', '🐧', '🦈', '🕊️'],
    oddIndex: 2,
    explanation:
        'Акула — рыба, она дышит жабрами и плавает плавниками. Утка, пингвин и голубь — птицы.',
  ),
  const OddLevel(
    items: ['🪑', '🛋️', '🚪', '🛏️'],
    oddIndex: 2,
    explanation:
        'Дверь — часть дома, её врезают в стену. А стул, диван и кровать — мебель.',
  ),
  const OddLevel(
    items: ['🐘', '🦛', '🦒', '🐆'],
    oddIndex: 3,
    explanation:
        'Леопард — хищник, он подкрадывается к добыче. Слон, бегемот и жираф — травоядные.',
  ),
  const OddLevel(
    items: ['🥨', '🥒', '🍿', '🍩'],
    oddIndex: 1,
    explanation:
        'Огурец — овощ из огорода, из него делают салат. Крендель, попкорн и пончик — перекусы.',
  ),
  const OddLevel(
    items: ['🐬', '🐙', '🦑', '🦐'],
    oddIndex: 0,
    explanation:
        'Дельфин — млекопитающее, у него есть лёгкие и он кормит детёнышей молоком. Осьминог, кальмар и креветка живут в воде без лёгких.',
  ),
  const OddLevel(
    items: ['✏️', '📏', '📖', '📐'],
    oddIndex: 2,
    explanation:
        'Книгу читают, а карандаш, линейка и угольник — инструменты, которыми чертят и рисуют.',
  ),
  const OddLevel(
    items: ['🐜', '🐢', '🐝', '🐛'],
    oddIndex: 1,
    explanation:
        'Черепаха — не насекомое: у неё четыре ноги и твёрдый панцирь. Муравей, пчела и гусеница — насекомые.',
  ),
  const OddLevel(
    items: ['🐘', '🦏', '🦅', '🐂'],
    oddIndex: 2,
    explanation:
        'Орёл — птица с перьями и крыльями. Слон, носорог и бык — тяжёлые четвероногие животные.',
  ),
  const OddLevel(
    items: ['10', '15', '21', '25'],
    oddIndex: 2,
    explanation:
        'Двадцать один не делится на пять без остатка, а 10, 15 и 25 делятся на пять.',
  ),
  const OddLevel(
    items: ['🦋', '🐝', '🦟', '🐠'],
    oddIndex: 3,
    explanation:
        'Рыба дышит жабрами и плавает плавниками, а бабочка, пчела и комар — насекомые с шестью ножками.',
  ),
  const OddLevel(
    items: ['🧣', '🎩', '🧢', '👒'],
    oddIndex: 0,
    explanation:
        'Шарф надевают на шею, а шляпа, шапка и кепка — головные уборы.',
  ),
  const OddLevel(
    items: ['🧱', '🎈', '🪵', '🪨'],
    oddIndex: 1,
    explanation:
        'Кирпич, бревно и камень — твёрдые и тяжёлые, из них строят. Шарик лёгкий и летает по воздуху.',
  ),
  const OddLevel(
    items: ['🎻', '🎺', '🥁', '🪑'],
    oddIndex: 3,
    explanation:
        'Скрипка, труба и барабан — музыкальные инструменты, на них играют мелодии. Стул — мебель.',
  ),
];

/// Уровни игры (открыты для автотестов).
List<OddLevel> get oddLevels => _oddLevels;

/// Игра «Лишний элемент»: найти предмет, который не подходит к остальным.
class OddOneOutGame extends StatefulWidget {
  const OddOneOutGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<OddOneOutGame> createState() => _OddOneOutGameState();
}

class _OddOneOutGameState extends State<OddOneOutGame> {
  late OddLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  String _message = 'Найди то, что не подходит к остальным!';

  static const GameInfo _game = GameInfo(
    id: 'odd',
    title: 'Лишний элемент',
    subtitle: '',
    emoji: '🔍',
    levelCount: 30,
  );

  @override
  void initState() {
    super.initState();
    _level = _oddLevels[widget.levelIndex % _oddLevels.length];
  }

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _message = 'Найди то, что не подходит к остальным!';
    });
  }

  void _choose(int index) {
    if (_won) return;
    if (index == _level.oddIndex) {
      final stars = _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);
      setState(() {
        _won = true;
        _message = _level.explanation;
      });
      widget.onFinished(stars);
    } else {
      setState(() {
        _mistakes++;
        _wrongIndex = index;
        _message = 'Это подходит! Поищи другой предмет 🙂';
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
                  child: HintBar(text: _message, color: AppTheme.pink),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: const Text(
                    'Найди лишний предмет:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 420,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            for (int i = 0; i < _level.items.length; i++)
                              _card(i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1),
                maxLevelIndex: _oddLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(int index) {
    final isWrong = _wrongIndex == index;
    final isCorrect = index == _level.oddIndex && _won;
    return GestureDetector(
      onTap: () => _choose(index),
      child: Container(
        decoration: BoxDecoration(
          color: isWrong
              ? Colors.red.shade50
              : (isCorrect ? Colors.green.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isWrong
                ? Colors.red
                : (isCorrect
                    ? Colors.green
                    : AppTheme.pink.withValues(alpha: 0.4)),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _level.items[index],
              style: const TextStyle(fontSize: 64),
            ),
          ),
        ),
      ),
    );
  }
}
