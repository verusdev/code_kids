import 'package:flutter/material.dart';

import '../python/python_interpreter.dart';
import '../python/python_runner.dart';
import 'code_editor.dart';
import 'code_widgets.dart';
import 'kid_button.dart';
import 'turtle_canvas.dart';

/// Общий редактор Python-кода для экранов «Урок» и «Песочница».
///
/// Собирает привычные детям элементы в одном месте и в одном порядке:
/// моноширинное поле кода → панель быстрых кнопок → кнопка(и) запуска →
/// консоль вывода → (опционально) холст черепашки.
///
/// Экран урока передаёт сюда дополнительно кнопку «Проверить»
/// ([extraAction]) и баннер обратной связи ([middle]) — порядок блоков
/// полностью совпадает с прежним экраном урока.
class PythonCodeEditor extends StatelessWidget {
  const PythonCodeEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.onRun,
    this.runLabel = 'Запустить',
    this.extraAction,
    this.middle,
    this.result,
    this.consolePlaceholder = 'Нажми «Запустить» — тут появится вывод…',
    this.turtleLabel = 'Рисунок черепашки:',
    this.turtleSegments,
  });

  /// Контроллер текста кода (принадлежит экрану).
  final TextEditingController controller;

  /// Фокус-нод для кнопок быстрого ввода.
  final FocusNode? focusNode;

  /// Если задан — показывается крупная кнопка «Запустить».
  final VoidCallback? onRun;

  /// Подпись кнопки запуска (по умолчанию «Запустить»).
  final String runLabel;

  /// Вторая кнопка рядом с «Запустить» (в уроке — «Проверить»).
  final Widget? extraAction;

  /// Блок между кнопками и консолью (в уроке — обратная связь).
  final Widget? middle;

  /// Результат запуска для консоли (`null` — показать подсказку).
  final PythonResult? result;

  /// Текст-заглушка консоли до первого запуска.
  final String consolePlaceholder;

  /// Подпись над холстом черепашки.
  final String turtleLabel;

  /// Если не `null` — под консолью показывается холст черепашки
  /// (пустой список рисует «Черепашка ещё ничего не нарисовала»).
  final List<TurtleSegment>? turtleSegments;

  static const Color _accent = Color(0xFF3776AB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CodeEditor(controller: controller, focusNode: focusNode),
        const SizedBox(height: 10),
        QuickCodeBar(controller: controller, focusNode: focusNode),
        const SizedBox(height: 14),
        if (onRun != null) ...[
          Row(
            children: [
              Expanded(
                child: KidButton(
                  label: runLabel,
                  icon: Icons.play_arrow_rounded,
                  color: _accent,
                  expand: true,
                  onPressed: onRun,
                ),
              ),
              if (extraAction != null) ...[
                const SizedBox(width: 10),
                Expanded(child: extraAction!),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (middle != null) ...[
          middle!,
          const SizedBox(height: 12),
        ],
        CodeConsole(result: result, placeholder: consolePlaceholder),
        if (turtleSegments != null) ...[
          const SizedBox(height: 12),
          Text(
            turtleLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          TurtleCanvas(segments: turtleSegments!),
        ],
      ],
    );
  }
}
