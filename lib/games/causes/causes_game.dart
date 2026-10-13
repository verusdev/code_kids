import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Вариант ответа в «Цепочке причин».
class CauseOption {
  const CauseOption(this.emoji, this.text);

  final String emoji;
  final String text;
}

/// Уровень игры «Цепочка причин»: выбрать следствие или причину.
class CauseLevel {
  const CauseLevel({
    required this.emoji,
    required this.prompt,
    required this.askCause,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Эмодзи ситуации.
  final String emoji;

  /// Описание ситуации.
  final String prompt;

  /// true  → «Что случилось раньше?» (ищем причину).
  /// false → «Что будет дальше?» (ищем следствие).
  final bool askCause;

  final List<CauseOption> options;
  final int correctIndex;
  final String explanation;
}

final List<CauseLevel> _causesLevels = [
  const CauseLevel(
    emoji: '☔',
    prompt: 'На улице пошёл сильный дождь.',
    askCause: false,
    options: [
      CauseOption('🌂', 'Возьму зонт и надену сапоги'),
      CauseOption('🩳', 'Выйду в шортах и майке'),
      CauseOption('🕯️', 'Зажгу свечку'),
    ],
    correctIndex: 0,
    explanation: 'Дождь 🌧️ — причина, а зонт 🌂 защищает от него. '
        'Это действие-следствие.',
  ),
  const CauseLevel(
    emoji: '🦶',
    prompt: 'Ноги промокли, пока шёл домой.',
    askCause: true,
    options: [
      CauseOption('💦', 'Я наступил в большую лужу'),
      CauseOption('🍲', 'Я поел суп'),
      CauseOption('😴', 'Я поспал'),
    ],
    correctIndex: 0,
    explanation: 'Лужа 💦 — причина, а мокрые ноги 🦶 — следствие. '
        'Причина случилась раньше.',
  ),
  const CauseLevel(
    emoji: '☀️',
    prompt: 'Солнце пригрело снег на площадке.',
    askCause: false,
    options: [
      CauseOption('💧', 'Снег растаял, появились лужи'),
      CauseOption('❄️', 'Стало ещё холоднее'),
      CauseOption('🌨️', 'Пошёл снег'),
    ],
    correctIndex: 0,
    explanation: 'Тепло солнца ☀️ растопило снег ❄️ — и появились лужи 💧.',
  ),
  const CauseLevel(
    emoji: '🪴',
    prompt: 'Цветок на подоконнике долго не поливали.',
    askCause: false,
    options: [
      CauseOption('🥀', 'Цветок засохнет'),
      CauseOption('🌷', 'Он станет выше и зацветёт'),
      CauseOption('🎨', 'Он станет разноцветным'),
    ],
    correctIndex: 0,
    explanation: 'Без воды 💧 растение вянет 🥀. Вода — важная часть для жизни.',
  ),
  const CauseLevel(
    emoji: '🪟',
    prompt: 'Утром на окне появился лёд.',
    askCause: true,
    options: [
      CauseOption('🌡️', 'Ночью стало очень холодно'),
      CauseOption('🔥', 'Ночью было жарко'),
      CauseOption('🌬️', 'Дул тёплый ветер'),
    ],
    correctIndex: 0,
    explanation: 'Холодная ночь ❄️ — причина, лёд на стекле 🪟 — следствие.',
  ),
  const CauseLevel(
    emoji: '⚽',
    prompt: 'Мяч положили на самый верх горки и отпустили.',
    askCause: false,
    options: [
      CauseOption('⬇️', 'Мяч покатился вниз'),
      CauseOption('⬆️', 'Мяч полетел вверх'),
      CauseOption('✨', 'Мяч исчез'),
    ],
    correctIndex: 0,
    explanation: 'Отпустил мяч ⚽ — он покатился вниз ⬇️. Так действует сила '
        'притяжения.',
  ),
  const CauseLevel(
    emoji: '🍵',
    prompt: 'Горячий чай постоял на столе полчаса.',
    askCause: false,
    options: [
      CauseOption('🌡️', 'Чай остынет'),
      CauseOption('🔥', 'Чай станет ещё горячее'),
      CauseOption('🧊', 'Чай превратится в лёд'),
    ],
    correctIndex: 0,
    explanation: 'Горячий чай 🍵 отдаёт тепло воздуху — и остывает. '
        'Это тоже следствие.',
  ),
  const CauseLevel(
    emoji: '💡',
    prompt: 'Свет в комнате внезапно погас.',
    askCause: true,
    options: [
      CauseOption('🔌', 'Отключили электричество'),
      CauseOption('🪟', 'Кто-то открыл окно'),
      CauseOption('🎵', 'Заиграла музыка'),
    ],
    correctIndex: 0,
    explanation: 'Нет электричества 🔌 — не горит свет 💡. Причина и следствие.',
  ),
  const CauseLevel(
    emoji: '🐛',
    prompt: 'Гусеница всё лето ела листья и росла.',
    askCause: false,
    options: [
      CauseOption('🦋', 'Она превратится в бабочку'),
      CauseOption('🐦', 'Она превратится в птицу'),
      CauseOption('🪨', 'Она превратится в камень'),
    ],
    correctIndex: 0,
    explanation: 'Гусеница 🐛 растёт и превращается в бабочку 🦋 — так '
        'устроена природа.',
  ),
  const CauseLevel(
    emoji: '💦',
    prompt: 'В воду бросили камень.',
    askCause: false,
    options: [
      CauseOption('🌊', 'По воде пойдут круги'),
      CauseOption('😐', 'Ничего не произойдёт'),
      CauseOption('🧊', 'Вода станет твёрдой'),
    ],
    correctIndex: 0,
    explanation: 'Камень толкнул воду 💦 — по ней пошли круги 🌊. '
        'Каждое действие оставляет след.',
  ),
  const CauseLevel(
    emoji: '🧊',
    prompt: 'Кубик льда лежал на солнце. Сначала от него осталась лужица, '
        'а к вечеру исчезла и она.',
    askCause: false,
    options: [
      CauseOption('💨', 'Лёд растаял, а вода превратилась в пар'),
      CauseOption('🧊', 'Лёд замёрз обратно и стал больше'),
      CauseOption('🥤', 'Вода впиталась в стакан'),
      CauseOption('🧽', 'Кто-то вытер воду тряпкой'),
    ],
    correctIndex: 0,
    explanation: 'Это цепочка из двух шагов: солнце ☀️ растопило лёд 🧊 — '
        'получилась вода 💧, а тепло превратило её в пар 💨.',
  ),
  const CauseLevel(
    emoji: '🌳',
    prompt: 'Утром тень от дерева была длинной, а в полдень стала совсем '
        'короткой.',
    askCause: true,
    options: [
      CauseOption('☀️', 'Солнце поднялось высоко в небо'),
      CauseOption('🌳', 'Дерево выросло за одно утро'),
      CauseOption('🌬️', 'Подул сильный ветер'),
      CauseOption('🌧️', 'Ночью прошёл дождь'),
    ],
    correctIndex: 0,
    explanation: 'Чем выше солнце ☀️, тем короче тень 🌳. В полдень солнце '
        'светит почти сверху — и тень прячется под деревом.',
  ),
  const CauseLevel(
    emoji: '🔦',
    prompt: 'В фонарик поставили новые батарейки, но он всё равно не светит. '
        'Внутри отошёл проводок от лампочки.',
    askCause: true,
    options: [
      CauseOption('🔌', 'Цепь разорвана, и ток не доходит до лампочки'),
      CauseOption('🔋', 'Батарейки разрядились за минуту'),
      CauseOption('💡', 'Лампочка светит слишком ярко'),
      CauseOption('🌙', 'На улице стало темно'),
    ],
    correctIndex: 0,
    explanation: 'Ток идёт по замкнутому кругу — по цепи 🔌. Проводок отошёл, '
        'круг разорван, и фонарик не горит даже с новыми батарейками 🔋.',
  ),
  const CauseLevel(
    emoji: '🦌',
    prompt: 'В лесу исчезли все волки. Через год олени ослабли и стали '
        'болеть, а травы на полянах стало меньше.',
    askCause: true,
    options: [
      CauseOption('🦌', 'Оленей стало слишком много, и еды не хватило всем'),
      CauseOption('🌧️', 'В лесу перестали идти дожди'),
      CauseOption('🐺', 'Олени испугались волков и убежали'),
      CauseOption('🌿', 'Трава выросла слишком высокой'),
    ],
    correctIndex: 0,
    explanation: 'Волки 🐺 охотились на оленей 🦌. Без волков оленей стало '
        'слишком много, травы на всех не хватило — и они ослабли.',
  ),
  const CauseLevel(
    emoji: '🤖',
    prompt: 'Робот каждые 5 минут поворачивает направо на четверть круга. '
        'В 12:00 он ехал на север.',
    askCause: false,
    options: [
      CauseOption('➡️', 'В 12:05 он поедет на восток'),
      CauseOption('⬆️', 'В 12:05 он поедет на север'),
      CauseOption('⬇️', 'В 12:05 он поедет на юг'),
      CauseOption('🛑', 'В 12:05 он остановится'),
    ],
    correctIndex: 0,
    explanation: 'Поворот направо меняет направление по кругу: север ➡️ '
        'восток. Команда робота 🤖 — причина, новое направление — следствие.',
  ),
];

/// Уровни игры (открыты для автотестов).
List<CauseLevel> get causesLevels => _causesLevels;

/// Игра «Цепочка причин»: ребёнок выбирает следствие или причину.
class CausesGame extends StatefulWidget {
  const CausesGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<CausesGame> createState() => _CausesGameState();
}

class _CausesGameState extends State<CausesGame> {
  late CauseLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  String _message = 'Подумай, что здесь связано.';

  static const GameInfo _game = GameInfo(
    id: 'causes',
    title: 'Цепочка причин',
    subtitle: '',
    emoji: '🔗',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _causesLevels[widget.levelIndex % _causesLevels.length];
    _message = _question;
  }

  String get _question =>
      _level.askCause ? 'Что случилось раньше?' : 'Что будет дальше?';

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _message = _question;
    });
  }

  void _choose(int index) {
    if (_won) return;
    if (index == _level.correctIndex) {
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
        _message = 'Не совсем. Подумай, что здесь причина, а что следствие 🤔';
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
                  child: HintBar(text: _message, color: AppTheme.teal),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _situationCard(),
                        const SizedBox(height: 20),
                        Text(
                          _question,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 0; i < _level.options.length; i++)
                          _optionCard(i),
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
                maxLevelIndex: _causesLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _situationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4), width: 3),
      ),
      child: Column(
        children: [
          Text(_level.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 10),
          Text(
            _level.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(int index) {
    final isWrong = _wrongIndex == index;
    final isRight = index == _level.correctIndex && _won;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _choose(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isWrong
                ? Colors.red.shade50
                : (isRight ? Colors.green.shade50 : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWrong
                  ? Colors.red
                  : (isRight
                      ? Colors.green
                      : AppTheme.teal.withValues(alpha: 0.5)),
              width: 3,
            ),
          ),
          child: Row(
            children: [
              Text(_level.options[index].emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _level.options[index].text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
