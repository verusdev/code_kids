import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Действие системы в «Умных правилах».
class RuleAction {
  const RuleAction(this.emoji, this.text);

  final String emoji;
  final String text;
}

/// Уровень игры «Умные правила»: у устройства есть правило «если — то».
///
/// Ребёнок смотрит на «показание датчика» и выбирает, что сделает система.
/// Так он видит обратную связь: система сама себя регулирует.
class RulesLevel {
  const RulesLevel({
    required this.deviceEmoji,
    required this.deviceName,
    required this.rule,
    required this.reading,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String deviceEmoji;
  final String deviceName;

  /// Правило устройства: «ЕСЛИ …, ТО …».
  final String rule;

  /// Текущее «показание» (что происходит сейчас).
  final String reading;

  final List<RuleAction> options;
  final int correctIndex;
  final String explanation;
}

final List<RulesLevel> _rulesLevels = [
  const RulesLevel(
    deviceEmoji: '🌡️',
    deviceName: 'Умный термостат',
    rule: 'ЕСЛИ станет холоднее 20°, ТО включить обогрев',
    reading: 'В комнате стало 15° ❄️',
    options: [
      RuleAction('🔥', 'Включить обогрев'),
      RuleAction('🌀', 'Включить вентилятор'),
      RuleAction('😐', 'Ничего не делать'),
    ],
    correctIndex: 0,
    explanation: '15° — холоднее 20°, значит термостат включает обогрев 🔥. '
        'Комната согреется — и он выключится сам.',
  ),
  const RulesLevel(
    deviceEmoji: '🌡️',
    deviceName: 'Умный термостат',
    rule: 'ЕСЛИ станет жарче 26°, ТО включить вентилятор',
    reading: 'В комнате стало 30° 🔥',
    options: [
      RuleAction('🌀', 'Включить вентилятор'),
      RuleAction('🔥', 'Включить обогрев'),
      RuleAction('🧣', 'Надеть шарф'),
    ],
    correctIndex: 0,
    explanation: '30° — жарче 26°, поэтому включается вентилятор 🌀. '
        'Стало прохладнее — он выключится.',
  ),
  const RulesLevel(
    deviceEmoji: '🚦',
    deviceName: 'Светофор',
    rule: 'ЕСЛИ по дороге едут машины, ТО зажечь красный',
    reading: 'Машины едут по дороге 🚗',
    options: [
      RuleAction('🔴', 'Зажечь красный свет'),
      RuleAction('🟢', 'Зажечь зелёный свет'),
      RuleAction('🟡', 'Просто мигать'),
    ],
    correctIndex: 0,
    explanation: 'Едут машины — горит красный 🔴, пешеходы ждут. '
        'Машины уедут — загорится зелёный 🟢.',
  ),
  const RulesLevel(
    deviceEmoji: '💡',
    deviceName: 'Умный свет',
    rule: 'ЕСЛИ темно и кто-то вошёл, ТО включить свет',
    reading: 'В комнате темно и кто-то вошёл 🌙',
    options: [
      RuleAction('💡', 'Включить свет'),
      RuleAction('🌑', 'Выключить свет'),
      RuleAction('🚪', 'Открыть дверь'),
    ],
    correctIndex: 0,
    explanation: 'Стало темно и кто-то вошёл — свет включается 💡. '
        'Когда никого не будет, он погаснет.',
  ),
  const RulesLevel(
    deviceEmoji: '⏰',
    deviceName: 'Будильник',
    rule: 'ЕСЛИ на часах 7:00, ТО звонить',
    reading: 'На часах ровно 7:00 🕖',
    options: [
      RuleAction('🔔', 'Зазвенеть'),
      RuleAction('📺', 'Включить мультики'),
      RuleAction('😴', 'Остаться спать'),
    ],
    correctIndex: 0,
    explanation: 'Наступило 7:00 — будильник звенит 🔔, пора вставать. '
        'Правило сработало само.',
  ),
  const RulesLevel(
    deviceEmoji: '🌱',
    deviceName: 'Автополив',
    rule: 'ЕСЛИ земля сухая, ТО полить цветок',
    reading: 'Земля стала сухой 🏜️',
    options: [
      RuleAction('💧', 'Полить цветок'),
      RuleAction('🧣', 'Укрыть цветок'),
      RuleAction('🌬️', 'Подуть на цветок'),
    ],
    correctIndex: 0,
    explanation: 'Земля сухая — включается полив 💧. Земля станет влажной, '
        'и вода выключится.',
  ),
  const RulesLevel(
    deviceEmoji: '☕',
    deviceName: 'Кофеварка',
    rule: 'ЕСЛИ вода закипела, ТО выключить нагрев',
    reading: 'Вода в кофеварке закипела 💨',
    options: [
      RuleAction('🛑', 'Выключить нагрев'),
      RuleAction('🔥', 'Греть дальше'),
      RuleAction('💧', 'Налить ещё воды'),
    ],
    correctIndex: 0,
    explanation: 'Вода закипела 💨 — нагрев выключается 🛑, чтобы не '
        'перегрелось. Это обратная связь.',
  ),
  const RulesLevel(
    deviceEmoji: '❄️',
    deviceName: 'Холодильник',
    rule: 'ЕСЛИ станет теплее 5°, ТО усилить холод',
    reading: 'Внутри стало 8° 🌡️',
    options: [
      RuleAction('🧊', 'Усилить холод'),
      RuleAction('🔥', 'Подогреть'),
      RuleAction('🚪', 'Открыть дверцу'),
    ],
    correctIndex: 0,
    explanation: 'Стало 8° — теплее 5°, холодильник усиливает холод 🧊. '
        'Остынет — и снова работает спокойно.',
  ),
  const RulesLevel(
    deviceEmoji: '🚿',
    deviceName: 'Умывальник',
    rule: 'ЕСЛИ поднесли руки, ТО дать воду',
    reading: 'Под струёй появились руки 🙌',
    options: [
      RuleAction('🚰', 'Дать воду'),
      RuleAction('🛑', 'Перекрыть воду'),
      RuleAction('📣', 'Громко сказать «привет»'),
    ],
    correctIndex: 0,
    explanation: 'Датчик заметил руки 🙌 и пустил воду 🚰. Убрал руки — '
        'вода остановится.',
  ),
  const RulesLevel(
    deviceEmoji: '🔔',
    deviceName: 'Умная дверь',
    rule: 'ЕСЛИ прозвенел звонок, ТО открыть дверь',
    reading: 'Кто-то нажал кнопку звонка 🔔',
    options: [
      RuleAction('🚪', 'Открыть дверь'),
      RuleAction('🔒', 'Запереть дверь'),
      RuleAction('🎵', 'Включить музыку'),
    ],
    correctIndex: 0,
    explanation: 'Прозвенел звонок 🔔 — дверь открывается 🚪. Так работает '
        'простое правило «если — то».',
  ),
  const RulesLevel(
    deviceEmoji: '🌿',
    deviceName: 'Умная теплица',
    rule: 'ЕСЛИ земля сухая И на улице тепло, ТО включить полив',
    reading: 'Земля сухая 🏜️, на улице +24° ☀️',
    options: [
      RuleAction('💧', 'Включить полив'),
      RuleAction('🧣', 'Укрыть растения'),
      RuleAction('🪟', 'Закрыть теплицу'),
    ],
    correctIndex: 0,
    explanation: 'Здесь нужны ОБА условия: и сухая земля, и тепло на улице. '
        'Оба сошлись — теплица включает полив 💧. Будь на улице холодно, '
        'полив бы не включился.',
  ),
  const RulesLevel(
    deviceEmoji: '💡',
    deviceName: 'Свет в коридоре',
    rule: 'ЕСЛИ темно И есть движение, ТО включить свет',
    reading: 'В коридоре темно 🌙, движения нет 🚫',
    options: [
      RuleAction('🌑', 'Оставить свет выключенным'),
      RuleAction('💡', 'Включить свет'),
      RuleAction('🌀', 'Включить вентилятор'),
    ],
    correctIndex: 0,
    explanation: 'После «если» стоит слово «И»: нужны и темнота, и движение. '
        'Движения нет — значит свет остаётся выключенным 🌑. Было бы «ИЛИ» — '
        'свет загорелся бы от одной темноты.',
  ),
  const RulesLevel(
    deviceEmoji: '🤖',
    deviceName: 'Робот-пылесос',
    rule: 'ЕСЛИ батарея почти пуста ИЛИ нажата кнопка «домой», ТО ехать на базу',
    reading: 'Батарея 12% 🪫, кнопку «домой» никто не нажимал 🔘',
    options: [
      RuleAction('🏠', 'Ехать на базу и заряжаться'),
      RuleAction('🧹', 'Мыть пол дальше'),
      RuleAction('🔌', 'Выключиться совсем'),
    ],
    correctIndex: 0,
    explanation: 'Здесь условия соединяет «ИЛИ»: хватит одного. Батарея почти '
        'пуста 🪫 — робот едет на базу 🏠, хотя кнопку «домой» не нажимали. '
        'Слово «ИЛИ» делает правило мягче.',
  ),
  const RulesLevel(
    deviceEmoji: '🏠',
    deviceName: 'Умный дом (воздух)',
    rule: 'ЕСЛИ воздух влажный И тёплый, ТО открыть форточку',
    reading: 'Влажность 85% 💧, температура 26° 🔥, свет включён 💡',
    options: [
      RuleAction('🪟', 'Открыть форточку'),
      RuleAction('🔥', 'Включить обогрев'),
      RuleAction('💤', 'Ничего не делать'),
    ],
    correctIndex: 0,
    explanation: 'Влажный воздух 💧 и тепло 🔥 — оба условия выполнены, '
        'поэтому форточка открывается 🪟. Правило смотрит только на '
        'влажность и температуру, а свет ему безразличен.',
  ),
  const RulesLevel(
    deviceEmoji: '🚗',
    deviceName: 'Умный автомобиль',
    rule: 'ЕСЛИ дверь открыта И ремень не пристёгнут, ТО пищать',
    reading: 'Дверь открыта 🚪, ремень не пристёгнут 🔗, скорость 0 км/ч',
    options: [
      RuleAction('🔔', 'Пищать и напоминать'),
      RuleAction('🚀', 'Ехать быстро'),
      RuleAction('🎵', 'Играть музыку'),
    ],
    correctIndex: 0,
    explanation: 'Дверь открыта И ремень не пристёгнут — оба условия сошлись, '
        'поэтому машина пищит 🔔 и просит пристегнуться. Застегнёшь ремень — '
        'писк прекратится.',
  ),
];

/// Уровни игры (открыты для автотестов).
List<RulesLevel> get rulesLevels => _rulesLevels;

/// Игра «Умные правила»: что сделает система по своему правилу.
class RulesGame extends StatefulWidget {
  const RulesGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<RulesGame> createState() => _RulesGameState();
}

class _RulesGameState extends State<RulesGame> {
  late RulesLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  String _message = 'Что сделает система по своему правилу?';

  static const GameInfo _game = GameInfo(
    id: 'rules',
    title: 'Умные правила',
    subtitle: '',
    emoji: '⚙️',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _rulesLevels[widget.levelIndex % _rulesLevels.length];
  }

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _message = 'Что сделает система по своему правилу?';
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
        _message = 'Посмотри ещё раз на правило: «если …, то …» 🤖';
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
                  child: HintBar(text: _message, color: AppTheme.sky),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _deviceCard(),
                        const SizedBox(height: 14),
                        _readingCard(),
                        const SizedBox(height: 18),
                        const Text(
                          'Что сделает система?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                maxLevelIndex: _rulesLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.sky.withValues(alpha: 0.4), width: 3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(_level.deviceEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _level.deviceName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.sky.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ПРАВИЛО',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _level.rule,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('📡', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _level.reading,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(int index) {
    final isWrong = _wrongIndex == index;
    final isRight = index == _level.correctIndex && _won;
    return GestureDetector(
      onTap: () => _choose(index),
      child: Container(
        width: 150,
        height: 108,
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
                    : AppTheme.sky.withValues(alpha: 0.5)),
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _level.options[index].emoji,
              style: const TextStyle(fontSize: 34),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _level.options[index].text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
