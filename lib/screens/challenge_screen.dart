import 'dart:async';

import 'package:flutter/material.dart';

import '../games/game_definition.dart';
import '../models/game_models.dart';
import '../services/challenge_service.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_button.dart';

/// Режим «Испытание»: ребёнок проходит самые трудные уровни всех игр подряд,
/// без подсказок, на время. Лучшее время сохраняется как рекорд.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  /// Все игры, которые входят в испытание (по одному — самому сложному — уровню).
  static List<GameInfo> get tasks => [...kGames, ...kSystemGames];

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;

  bool _running = false;
  bool _finished = false;
  int _done = 0;
  int _stars = 0;
  int _elapsed = 0;
  bool _newRecord = false;

  @override
  void dispose() {
    _ticker?.cancel();
    ChallengeSession.stop();
    super.dispose();
  }

  void _startTimer() {
    _watch
      ..reset()
      ..start();
    ChallengeSession.seconds.value = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = _watch.elapsed.inSeconds;
      ChallengeSession.seconds.value = _elapsed;
      if (mounted) setState(() {});
    });
  }

  Future<void> _begin() async {
    final tasks = ChallengeScreen.tasks;
    setState(() {
      _running = true;
      _finished = false;
      _done = 0;
      _stars = 0;
      _elapsed = 0;
      _newRecord = false;
    });
    ChallengeSession.start(tasks.length);
    _startTimer();
    SoundService.tap();

    for (int i = 0; i < tasks.length; i++) {
      ChallengeSession.current = i + 1;
      final completed = await _playTask(tasks[i]);
      if (!completed) break; // ребёнок вышел из уровня — прерываем испытание
      _done++;
    }

    _ticker?.cancel();
    _elapsed = _watch.elapsed.inSeconds;
    _watch.stop();
    final allDone = _done == tasks.length;
    ChallengeSession.stop();

    if (allDone) {
      _newRecord = await ChallengeService.instance.record(_elapsed);
      if (_newRecord) {
        SoundService.win();
        SpeechService.instance.speak('Новый рекорд! Ты прошёл испытание!');
      }
    }
    if (mounted) {
      setState(() {
        _running = false;
        _finished = true;
      });
    }
  }

  /// Запускает один уровень и ждёт, пока ребёнок его закончит.
  /// Возвращает true, если уровень был пройден (нажата кнопка «Дальше»).
  Future<bool> _playTask(GameInfo game) async {
    var solved = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => buildGameScreen(
          gameId: game.id,
          levelIndex: game.levelCount - 1,
          onFinished: (stars) {
            solved = true;
            _stars += stars;
          },
        ),
      ),
    );
    return solved;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆  Испытание'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_finished) return _result();
    if (_running) return _progress();
    return _intro();
  }

  Widget _intro() {
    final best = ChallengeService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          const Text(
            'Испытание',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Самые трудные уровни всех игр — подряд, без подсказок и на время. '
            'Пройди все задания быстрее всех!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.yellow.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Заданий: ${ChallengeScreen.tasks.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  best.hasRecord
                      ? '🏅 Твой рекорд: ${formatDuration(best.bestSeconds)}'
                      : '🏅 Рекорда пока нет — поставь первый!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          KidButton(
            label: 'Начать испытание',
            icon: Icons.play_arrow_rounded,
            color: AppTheme.pink,
            expand: true,
            onPressed: _begin,
          ),
          const SizedBox(height: 10),
          KidButton(
            label: 'Домой',
            icon: Icons.home_rounded,
            color: AppTheme.purple,
            expand: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Приготовься… 🚀',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _result() {
    final allDone = _done == ChallengeScreen.tasks.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            allDone ? '🎉' : '⏸️',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            allDone ? 'Испытание пройдено!' : 'Испытание прервано',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _statRow('✅ Заданий пройдено', '$_done из ${ChallengeScreen.tasks.length}'),
          _statRow('⏱️ Время', formatDuration(_elapsed)),
          _statRow('⭐ Звёзд', '$_stars'),
          if (_newRecord) ...[
            const SizedBox(height: 8),
            const Text(
              '🏆 Новый рекорд!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.pink,
              ),
            ),
          ] else if (allDone && ChallengeService.instance.hasRecord) ...[
            const SizedBox(height: 8),
            Text(
              '🏅 Рекорд: ${formatDuration(ChallengeService.instance.bestSeconds)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 24),
          KidButton(
            label: 'Ещё раз',
            icon: Icons.replay_rounded,
            color: AppTheme.orange,
            expand: true,
            onPressed: _begin,
          ),
          const SizedBox(height: 10),
          KidButton(
            label: 'Домой',
            icon: Icons.home_rounded,
            color: AppTheme.purple,
            expand: true,
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
