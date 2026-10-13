import 'package:flutter/material.dart';

import '../../games/game_common.dart';
import '../../models/python_lesson.dart';
import '../../python/lessons/python_course.dart';
import '../../python/python_runner.dart';
import '../../services/daily_service.dart';
import '../../services/progress_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/code_editor.dart';
import '../../widgets/code_widgets.dart';
import '../../widgets/kid_button.dart';
import '../../widgets/task_speech_button.dart';
import '../../widgets/turtle_canvas.dart';

/// Экран одного урока: объяснение, пример, задание и консоль.
class PythonLessonScreen extends StatefulWidget {
  const PythonLessonScreen({super.key, required this.lessonIndex});

  final int lessonIndex;

  @override
  State<PythonLessonScreen> createState() => _PythonLessonScreenState();
}

class _PythonLessonScreenState extends State<PythonLessonScreen> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  PythonResult? _exampleResult;
  PythonResult? _taskResult;
  String? _feedback;
  bool _feedbackGood = false;
  bool _showHint = false;
  bool _solved = false;
  int _stars = 0;
  int _fails = 0;

  static const Color _accent = Color(0xFF3776AB);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: pythonLessons[widget.lessonIndex].startCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runExample() {
    final lesson = pythonLessons[widget.lessonIndex];
    setState(() => _exampleResult = PythonRunner.run(
          lesson.exampleCode,
          inputs: lesson.exampleInputs,
        ));
  }

  void _runTask() {
    final lesson = pythonLessons[widget.lessonIndex];
    final result = PythonRunner.run(_controller.text, inputs: lesson.inputs);
    setState(() {
      _taskResult = result;
      _feedback = null;
    });
  }

  void _check() {
    final lesson = pythonLessons[widget.lessonIndex];
    final result = PythonRunner.run(_controller.text, inputs: lesson.inputs);
    if (!result.ok) {
      _fails++;
      SoundService.wrong();
      setState(() {
        _taskResult = result;
        _feedbackGood = false;
        _feedback = 'Пока есть ошибка. Посмотри сообщение в консоли ниже и попробуй снова.';
      });
      return;
    }
    if (lesson.matches(result.outputText)) {
      final stars = (3 - _fails).clamp(1, 3);
      SoundService.win();
      ProgressService.instance.record(
        'python',
        widget.lessonIndex,
        stars,
        pythonLessons.length,
      );
      DailyService.instance.recordLevel(gameId: 'python', stars: stars);
      setState(() {
        _taskResult = result;
        _solved = true;
        _stars = stars;
      });
    } else {
      _fails++;
      SoundService.wrong();
      setState(() {
        _taskResult = result;
        _feedbackGood = false;
        _feedback =
            'Вывод пока не совпал.\nНужно напечатать:\n«${lesson.expectedOutput}»';
      });
    }
  }

  void _reset() {
    setState(() {
      _controller.text = pythonLessons[widget.lessonIndex].startCode;
      _exampleResult = null;
      _taskResult = null;
      _feedback = null;
      _showHint = false;
      _solved = false;
      _fails = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = pythonLessons[widget.lessonIndex];
    final isLast = widget.lessonIndex == pythonLessons.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('🐍 Урок ${widget.lessonIndex + 1}')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _titleHeader(lesson),
              const SizedBox(height: 14),
              _card(
                emoji: '📖',
                title: 'Объяснение',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in lesson.theory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          p,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                emoji: '▶️',
                title: 'Пример',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CodeBlock(code: lesson.exampleCode),
                    const SizedBox(height: 12),
                    KidButton(
                      label: 'Запустить пример',
                      icon: Icons.play_arrow_rounded,
                      color: _accent,
                      expand: true,
                      onPressed: _runExample,
                    ),
                    const SizedBox(height: 10),
                    CodeConsole(
                      result: _exampleResult,
                      placeholder: 'Результат примера появится здесь…',
                    ),
                    if (lesson.drawsTurtle) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Рисунок черепашки:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TurtleCanvas(
                        segments: _exampleResult?.turtleSegments ?? const [],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                emoji: '✏️',
                title: 'Задание',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.task,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TaskSpeechButton(
                      text: lesson.task,
                      label: 'Прочитать задание',
                      color: _accent,
                    ),
                    const SizedBox(height: 8),
                    CodeEditor(controller: _controller, focusNode: _focusNode),
                    const SizedBox(height: 10),
                    QuickCodeBar(
                      controller: _controller,
                      focusNode: _focusNode,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: KidButton(
                            label: 'Запустить',
                            icon: Icons.play_arrow_rounded,
                            color: _accent,
                            expand: true,
                            onPressed: _runTask,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KidButton(
                            label: 'Проверить',
                            icon: Icons.check_rounded,
                            color: const Color(0xFF00B894),
                            expand: true,
                            onPressed: _check,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_feedback != null) ...[
                      _feedbackBanner(),
                      const SizedBox(height: 12),
                    ],
                    CodeConsole(
                      result: _taskResult,
                      placeholder: 'Нажми «Запустить» — тут появится вывод…',
                    ),
                    if (lesson.drawsTurtle) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Рисунок черепашки:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TurtleCanvas(
                        segments: _taskResult?.turtleSegments ?? const [],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showHint = !_showHint),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: Text(_showHint ? 'Спрятать подсказку' : 'Подсказка'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Сбросить код'),
                        ),
                      ],
                    ),
                    if (_showHint) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          lesson.hint,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_solved)
            WinOverlay(
              game: kPythonCourse,
              stars: _stars,
              maxLevelIndex: isLast ? 0 : 1,
              onRetry: _reset,
            ),
        ],
      ),
    );
  }

  Widget _titleHeader(PythonLesson lesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.goal,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String emoji,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _feedbackBanner() {
    final color = _feedbackGood ? const Color(0xFF00B894) : const Color(0xFFE17055);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Text(
        _feedback!,
        style: TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
