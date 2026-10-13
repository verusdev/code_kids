import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Один шаг алгоритма.
class StepItem {
  const StepItem(this.emoji, this.text);

  final String emoji;
  final String text;
}

/// Уровень игры «Порядок действий».
class StepsLevel {
  const StepsLevel({required this.title, required this.steps});

  final String title;

  /// Шаги в правильном порядке.
  final List<StepItem> steps;
}

const List<StepsLevel> _stepsLevels = [
  StepsLevel(
    title: 'Утро перед школой',
    steps: [
      StepItem('🛏️', 'Проснулся'),
      StepItem('🪥', 'Почистил зубы'),
      StepItem('🥣', 'Позавтракал'),
      StepItem('🎒', 'Пошёл в школу'),
    ],
  ),
  StepsLevel(
    title: 'Помой руки',
    steps: [
      StepItem('🚰', 'Открыл кран'),
      StepItem('🧼', 'Намылил руки'),
      StepItem('💦', 'Смыл пену'),
      StepItem('🧻', 'Вытер руки'),
    ],
  ),
  StepsLevel(
    title: 'Посади дерево',
    steps: [
      StepItem('🕳️', 'Выкопал ямку'),
      StepItem('🌱', 'Положил росток'),
      StepItem('⛰️', 'Засыпал землёй'),
      StepItem('💧', 'Полил водой'),
    ],
  ),
  StepsLevel(
    title: 'Собери портфель',
    steps: [
      StepItem('📚', 'Взял учебники'),
      StepItem('✏️', 'Положил пенал'),
      StepItem('🥪', 'Сложил завтрак'),
      StepItem('🎒', 'Закрыл портфель'),
    ],
  ),
  StepsLevel(
    title: 'Свари компот',
    steps: [
      StepItem('🍎', 'Помыл фрукты'),
      StepItem('🔪', 'Нарезал фрукты'),
      StepItem('🍲', 'Положил в кастрюлю'),
      StepItem('💧', 'Налил воду'),
      StepItem('🔥', 'Сварил компот'),
    ],
  ),
  StepsLevel(
    title: 'Постирай футболку',
    steps: [
      StepItem('👕', 'Взял футболку'),
      StepItem('🧼', 'Намылил футболку'),
      StepItem('💦', 'Прополоскал'),
      StepItem('🌬️', 'Высушил'),
    ],
  ),
  StepsLevel(
    title: 'Приготовь бутерброд',
    steps: [
      StepItem('🍞', 'Взял хлеб'),
      StepItem('🧈', 'Намазал масло'),
      StepItem('🧀', 'Положил сыр'),
      StepItem('🥪', 'Съел бутерброд'),
    ],
  ),
  StepsLevel(
    title: 'Полей цветок',
    steps: [
      StepItem('🪴', 'Взял лейку'),
      StepItem('🚰', 'Налил воду'),
      StepItem('💧', 'Полил цветок'),
      StepItem('☀️', 'Поставил на солнце'),
    ],
  ),
  StepsLevel(
    title: 'Сделай уроки',
    steps: [
      StepItem('📖', 'Открыл учебник'),
      StepItem('✏️', 'Решил задачу'),
      StepItem('✅', 'Проверил ответ'),
      StepItem('🎒', 'Сложил в портфель'),
    ],
  ),
  StepsLevel(
    title: 'Испеки блины',
    steps: [
      StepItem('🥣', 'Замесил тесто'),
      StepItem('🔥', 'Разогрел сковороду'),
      StepItem('🥄', 'Налил тесто'),
      StepItem('🍳', 'Поджарил блин'),
      StepItem('🍯', 'Помазал мёдом'),
    ],
  ),
  StepsLevel(
    title: 'Отсортируй числа по возрастанию',
    steps: [
      StepItem('📋', 'Взял список чисел'),
      StepItem('🔍', 'Сравнил два числа рядом'),
      StepItem('🔁', 'Поменял их местами, если больше слева'),
      StepItem('➡️', 'Перешёл к следующей паре'),
      StepItem('🔄', 'Повторил проход, пока были перестановки'),
      StepItem('✅', 'Проверил: каждое число не больше следующего'),
      StepItem('🏁', 'Отдал готовый отсортированный список'),
    ],
  ),
  StepsLevel(
    title: 'Найди самое большое число',
    steps: [
      StepItem('🏆', 'Взял первое число как рекорд'),
      StepItem('👀', 'Посмотрел следующее число в списке'),
      StepItem('⚖️', 'Сравнил его с рекордом'),
      StepItem('⬆️', 'Обновил рекорд, если число больше'),
      StepItem('🔂', 'Повторил для всех оставшихся чисел'),
      StepItem('📣', 'Назвал победителя — самое большое число'),
    ],
  ),
  StepsLevel(
    title: 'Собери робота',
    steps: [
      StepItem('📦', 'Разложил детали из коробки'),
      StepItem('🔧', 'Собрал корпус и каркас'),
      StepItem('🦿', 'Прикрутил руки и колёса'),
      StepItem('🔌', 'Соединил провода с мотором'),
      StepItem('🔋', 'Вставил батарейки'),
      StepItem('💡', 'Нажал кнопку включения'),
      StepItem('🕹️', 'Проверил: робот слушается команд'),
    ],
  ),
  StepsLevel(
    title: 'Напечатай слово в программе',
    steps: [
      StepItem('🖥️', 'Открыл редактор кода'),
      StepItem('⌨️', 'Написал команду вывода на экран'),
      StepItem('🔤', 'Вставил нужное слово в кавычки'),
      StepItem('💾', 'Сохранил программу'),
      StepItem('▶️', 'Запустил программу'),
      StepItem('👀', 'Посмотрел, что появилось на экране'),
      StepItem('✅', 'Сверил слово и исправил ошибку, если она есть'),
    ],
  ),
  StepsLevel(
    title: 'Завари чай по шагам с проверкой',
    steps: [
      StepItem('🫗', 'Налил воду в чайник'),
      StepItem('🔥', 'Вскипятил воду'),
      StepItem('🍵', 'Положил чайный пакетик в чашку'),
      StepItem('🫖', 'Залил пакетик кипятком'),
      StepItem('⏳', 'Подождал три минуты'),
      StepItem('👅', 'Попробовал: не слишком ли крепко?'),
      StepItem('🍯', 'Добавил мёд, если чай горький'),
    ],
  ),
];

/// Уровни игры (открыты для автотестов).
List<StepsLevel> get stepsLevels => _stepsLevels;

/// Игра «Порядок действий»: расставить шаги алгоритма в правильном порядке.
class StepsOrderGame extends StatefulWidget {
  const StepsOrderGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<StepsOrderGame> createState() => _StepsOrderGameState();
}

class _StepsOrderGameState extends State<StepsOrderGame> {
  late StepsLevel _level;

  /// Порядок показа доступных шагов (индексы в _level.steps).
  late List<int> _available;

  /// Уже поставленные шаги (в правильном порядке, начиная с 0).
  int _placed = 0;

  int _mistakes = 0;
  bool _won = false;
  String _message = 'Нажимай на шаги по порядку: что сначала, что потом?';

  static const GameInfo _game = GameInfo(
    id: 'steps',
    title: 'Порядок действий',
    subtitle: '',
    emoji: '📋',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = _stepsLevels[widget.levelIndex % _stepsLevels.length];
    _shuffle();
  }

  void _shuffle() {
    final idx = List<int>.generate(_level.steps.length, (i) => i);
    // Фиксированное зерно — чтобы порядок не менялся при перерисовке,
    // но перемешивание всё же происходило.
    idx.shuffle(Random(widget.levelIndex + 1));
    _available = idx;
    _placed = 0;
    _mistakes = 0;
    _won = false;
    _message = 'Нажимай на шаги по порядку: что сначала, что потом?';
  }

  void _restart() {
    setState(_shuffle);
  }

  void _tapStep(int stepIndex) {
    if (_won) return;
    if (stepIndex == _placed) {
      setState(() {
        _placed++;
        _available.remove(stepIndex);
        if (_placed == _level.steps.length) {
          _won = true;
          _message = 'Правильный алгоритм! 🎉';
          final stars = _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);
          widget.onFinished(stars);
        } else {
          _message = 'Отлично! Что будет дальше?';
        }
      });
    } else {
      setState(() {
        _mistakes++;
        _message = 'Так пока рано. Подумай, какой шаг идёт раньше 🙂';
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    _level.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: HintBar(text: _message, color: AppTheme.sky),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _slots(),
                        const SizedBox(height: 24),
                        if (_available.isNotEmpty) ...[
                          const Text(
                            'Доступные шаги:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final i in _available) _availableChip(i),
                            ],
                          ),
                        ],
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
                maxLevelIndex: _stepsLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _slots() {
    return Column(
      children: [
        for (int i = 0; i < _level.steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: i < _placed
                  ? AppTheme.sky.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: i == _placed
                    ? AppTheme.sky
                    : Colors.grey.shade300,
                width: i == _placed ? 3 : 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i < _placed
                        ? AppTheme.sky
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i < _placed ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (i < _placed) ...[
                  Text(_level.steps[i].emoji,
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _level.steps[i].text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Text(
                      '…',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _availableChip(int stepIndex) {
    final step = _level.steps[stepIndex];
    return GestureDetector(
      onTap: () => _tapStep(stepIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.sky, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(step.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              step.text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
