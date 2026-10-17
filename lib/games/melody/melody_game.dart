import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kid_button.dart';
import '../game_common.dart';
import 'melody_levels.dart';

/// Акцентный цвет игры (из общей палитры темы).
Color get _melodyColor => AppTheme.gameColors['melody'] ?? AppTheme.purple;

/// Игра «Собери мелодию»: ребёнок видит и слушает короткую мелодию из нот, а
/// затем выкладывает её сам, нажимая крупные кнопки-ноты по порядку. Учит
/// последовательности и внимательности — нота за нотой, шаг за шагом.
///
/// Звук «играем» мягко: системный щелчок [SoundService.tap] на каждую ноту и
/// анимация активной плитки. Никаких новых пакетов и звуковых файлов.
class MelodyGame extends StatefulWidget {
  const MelodyGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<MelodyGame> createState() => _MelodyGameState();
}

class _MelodyGameState extends State<MelodyGame> {
  late MelodyLevel _level;

  /// Ноты, которые ребёнок уже выложил (в порядке нажатия).
  final List<MusicNote> _answer = [];

  /// Сколько раз проверка не совпала («попытки»). По ним считаем звёзды.
  int _failedRuns = 0;

  /// Индекс «звучащей» ноты: в цели или в ответе ребёнка.
  int? _soundingTarget;
  int? _soundingAnswer;

  /// Индекс первой неверной ноты в ответе (подсветка после проверки).
  int? _badIndex;

  /// Идёт проигрывание — кнопки временно не реагируют.
  bool _playing = false;

  /// Уровень решён (мелодия совпала).
  bool _won = false;

  /// Показать оверлей победы.
  bool _showWin = false;

  String _message = '';

  static const GameInfo _game = GameInfo(
    id: 'melody',
    title: 'Собери мелодию',
    subtitle: 'Составь мелодию из нот',
    emoji: '🎵',
    levelCount: 15,
  );

  @override
  void initState() {
    super.initState();
    _level = melodyLevels[widget.levelIndex % melodyLevels.length];
    _message = _defaultMessage;
  }

  String get _defaultMessage =>
      'Посмотри на мелодию и выложи её из нот по порядку 🎵';

  /// Звёзды: 3 — если угадал с первой попытки, 2 — со второй,
  /// 1 — с третьей и далее (как в остальных играх проекта).
  int get _stars => (3 - _failedRuns).clamp(1, 3);

  void _restart() {
    setState(() {
      _answer.clear();
      _failedRuns = 0;
      _soundingTarget = null;
      _soundingAnswer = null;
      _badIndex = null;
      _playing = false;
      _won = false;
      _showWin = false;
      _message = _defaultMessage;
    });
  }

  // ────────────────────────────── действия ──────────────────────────────

  /// Ребёнок нажал кнопку-ноту: добавляем её в конец дорожки.
  void _addNote(MusicNote note) {
    if (_playing || _won) return;
    if (_answer.length >= _level.target.length) {
      setState(
        () =>
            _message = 'Дорожка уже полная. Нажми «Проверить» или «Стереть» 🙂',
      );
      return;
    }
    SoundService.tap();
    final index = _answer.length;
    setState(() {
      _answer.add(note);
      _badIndex = null;
      _soundingAnswer = index;
      _message = 'Хорошо! Теперь следующая нота 🎵';
    });
    _stopSoundingAnswerSoon(index);
  }

  void _removeLast() {
    if (_playing || _won || _answer.isEmpty) return;
    setState(() {
      _answer.removeLast();
      _badIndex = null;
      _soundingAnswer = null;
      _message = 'Убрали последнюю ноту. Продолжай 🙂';
    });
  }

  void _eraseAll() {
    if (_playing || _won || _answer.isEmpty) return;
    setState(() {
      _answer.clear();
      _badIndex = null;
      _soundingAnswer = null;
      _message = 'Начнём заново. Выложи мелодию с первой ноты 🎵';
    });
  }

  void _useHint() {
    if (_playing || _won) return;
    setState(() => _message = 'Подсказка: ${_level.hint}');
  }

  /// Проигрываем указанную ноту: подсветка + короткий звук.
  Future<void> _playNote(int index, {required bool target}) async {
    setState(() {
      if (target) {
        _soundingTarget = index;
      } else {
        _soundingAnswer = index;
      }
    });
    SoundService.tap();
    await Future<void>.delayed(const Duration(milliseconds: 340));
  }

  Future<void> _stopSoundingAnswerSoon(int index) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _playing) return;
    if (_soundingAnswer == index) {
      setState(() => _soundingAnswer = null);
    }
  }

  /// Кнопка «Послушать»: показываем и «играем» правильную мелодию.
  Future<void> _playTarget() async {
    if (_playing || _won) return;
    setState(() {
      _playing = true;
      _badIndex = null;
      _message = 'Слушай мелодию… 🔊';
    });
    for (var i = 0; i < _level.target.length; i++) {
      if (!mounted) return;
      await _playNote(i, target: true);
    }
    if (!mounted) return;
    setState(() {
      _soundingTarget = null;
      _playing = false;
      _message = _defaultMessage;
    });
  }

  /// Кнопка «Проверить»: играем ответ ребёнка и сравниваем с целью.
  Future<void> _check() async {
    if (_playing || _won) return;
    if (_answer.length != _level.target.length) {
      setState(
        () => _message =
            'Мелодия ещё не готова: нужно ${_level.target.length} нот, '
            'а у тебя ${_answer.length} 🙂',
      );
      return;
    }
    setState(() {
      _playing = true;
      _badIndex = null;
      _message = 'Слушаем твою мелодию… 🎵';
    });
    for (var i = 0; i < _answer.length; i++) {
      if (!mounted) return;
      await _playNote(i, target: false);
    }
    if (!mounted) return;

    final bad = _firstMismatch();
    if (bad == null) {
      setState(() {
        _soundingAnswer = null;
        _playing = false;
        _won = true;
        _message = _level.explanation;
      });
      widget.onFinished(_stars);
    } else {
      SoundService.wrong();
      setState(() {
        _soundingAnswer = null;
        _playing = false;
        _failedRuns++;
        _badIndex = bad;
        _message =
            'Почти получилось! Послушай ещё раз и проверь ноту №${bad + 1} 🙂';
      });
    }
  }

  /// Индекс первой ноты, где ответ расходится с целью (или null, если совпало).
  int? _firstMismatch() {
    for (var i = 0; i < _level.target.length; i++) {
      if (i >= _answer.length || _answer[i] != _level.target[i]) return i;
    }
    return null;
  }

  // ────────────────────────────── внешний вид ───────────────────────────

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
                  child: HintBar(text: _message, color: _melodyColor),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _targetCard(),
                            const SizedBox(height: 16),
                            _answerCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _noteKeyboard(),
                _controls(),
                const SizedBox(height: 12),
              ],
            ),
            if (_showWin)
              WinOverlay(
                game: _game,
                stars: _stars,
                maxLevelIndex: melodyLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  /// Карточка с правильной мелодией и кнопкой «Послушать».
  Widget _targetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _melodyColor.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎵', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _level.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Вот мелодия, которую надо повторить:',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _level.target.length; i++)
                _noteChip(
                  note: _level.target[i],
                  number: i + 1,
                  active: _soundingTarget == i,
                ),
            ],
          ),
          const SizedBox(height: 14),
          KidButton(
            label: 'Послушать мелодию',
            emoji: '🔊',
            color: _melodyColor,
            expand: true,
            onPressed: _playing ? null : _playTarget,
          ),
        ],
      ),
    );
  }

  /// Карточка «Твоя мелодия»: дорожка из выложенных нот и пустые клетки.
  Widget _answerCard() {
    final total = _level.target.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _melodyColor.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✍️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Твоя мелодия:',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              _answerCount(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < total; i++)
                if (i < _answer.length)
                  _noteChip(
                    note: _answer[i],
                    number: i + 1,
                    active: _soundingAnswer == i,
                    wrong: _badIndex == i,
                  )
                else
                  _emptySlot(i + 1, active: !_won && _answer.length == i),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: KidButton(
                  label: 'Убрать',
                  icon: Icons.backspace_rounded,
                  color: AppTheme.orange,
                  expand: true,
                  onPressed: (_playing || _won || _answer.isEmpty)
                      ? null
                      : _removeLast,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KidButton(
                  label: 'Стереть',
                  icon: Icons.delete_sweep_rounded,
                  color: AppTheme.pink,
                  expand: true,
                  onPressed: (_playing || _won || _answer.isEmpty)
                      ? null
                      : _eraseAll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${_answer.length} / ${_level.target.length}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  /// Плитка ноты (в цели или в ответе).
  Widget _noteChip({
    required MusicNote note,
    int? number,
    bool active = false,
    bool wrong = false,
  }) {
    final bg = wrong ? Colors.red.shade400 : note.color;
    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 160),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.7),
            width: active ? 3 : 2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: note.color.withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    note.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            if (number != null)
              Positioned(
                left: 6,
                top: 2,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (wrong)
              const Positioned(
                right: 4,
                bottom: 2,
                child: Text('❌', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  /// Пустая клетка дорожки с номером позиции.
  Widget _emptySlot(int number, {bool active = false}) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? _melodyColor : Colors.grey.shade300,
          width: active ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  /// Крупные кнопки-ноты, доступные на уровне.
  Widget _noteKeyboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (final note in _level.palette) _noteButton(note)],
      ),
    );
  }

  Widget _noteButton(MusicNote note) {
    final enabled = !_playing && !_won;
    return Semantics(
      label: 'Нота ${note.label}',
      button: true,
      child: GestureDetector(
        onTap: enabled ? () => _addNote(note) : null,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: enabled ? note.color : note.color.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: note.color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                note.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Нижние кнопки: проверка и подсказка (или «Забрать звёзды» после победы).
  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _won
          ? KidButton(
              label: 'Забрать звёзды ⭐',
              icon: Icons.star_rounded,
              color: AppTheme.yellow,
              expand: true,
              onPressed: () => setState(() => _showWin = true),
            )
          : Row(
              children: [
                Expanded(
                  child: KidButton(
                    label: 'Проверить',
                    icon: Icons.play_arrow_rounded,
                    color: AppTheme.teal,
                    expand: true,
                    onPressed: _playing ? null : _check,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KidButton(
                    label: 'Подсказка',
                    emoji: '💡',
                    color: AppTheme.orange,
                    expand: true,
                    onPressed: _playing ? null : _useHint,
                  ),
                ),
              ],
            ),
    );
  }
}
