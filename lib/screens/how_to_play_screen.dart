import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../python/lessons/python_course.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot.dart';

/// Экран с инструкцией: как играть в каждую мини-игру.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const Map<String, String> _tips = {
    'maze':
        'Собери программу из команд «Вперёд», «Налево», «Направо». '
            'Нажми «Запустить» — робот выполнит их по очереди. Доведи его до флажка 🚩',
    'stars':
        'Сложи путь из стрелок так, чтобы персонаж собрал все звёзды ⭐. '
            'Кирпичи 🧱 обходить нельзя!',
    'pattern':
        'Посмотри на ряд фигур и угадай, что должно идти дальше. '
            'Найди закономерность и выбери подходящую карточку.',
    'odd':
        'Среди четырёх картинок найди ту, которая не подходит к остальным. '
            'Подумай, чем похожи остальные.',
    'steps':
        'Расставь шаги в правильном порядке: что делают сначала, а что потом. '
            'Нажимай на шаги по одному.',
    'blocks':
        'Собирай программу из блоков. Блок «Повторить N раз» заменяет много '
            'одинаковых команд, а «Если впереди стена» — помогает роботу самому '
            'повернуть. Нажми «Запустить» и доведи робота до флажка 🚩.',
    'pixel':
        'Рисуй картинку из блоков: «Закрась», «Вправо», «Вниз» и «Повторить». '
            'Призрачные клетки показывают, что нужно закрасить. Совпадёт точно — '
            'получишь звёзды!',
    'parts':
        'Посмотри на систему (растение, круговорот воды, фонарик…) и найди '
            'пропавшую часть ❓. Выбери деталь, которой не хватает, — и узнаешь, '
            'зачем она нужна.',
    'causes':
        'Прочитай, что случилось, и подумай: что будет дальше 🔜 или что было '
            'раньше ⬅️? Так ты учишься находить причину и следствие.',
    'rules':
        'У устройства есть правило «ЕСЛИ …, ТО …». Посмотри на показание '
            'датчика 📡 и выбери, что сделает система. Она сама себя '
            'регулирует — это обратная связь!',
    'python':
        'Здесь ты научишься писать настоящий код на языке Python! '
            'Читай объяснение, запускай пример и решай задания: print(), '
            'переменные, условия, циклы и функции.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Как играть?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Mascot(
            message:
                'Привет! Я кот Байт. Я помогу тебе учиться программировать. '
                'За каждый уровень ты получаешь до 3 звёздочек!',
            emoji: '🐱',
          ),
          const SizedBox(height: 20),
          ...<GameInfo>[...kGames, ...kSystemGames, kPythonCourse].map(
            (g) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border(
                  left: BorderSide(color: g.color, width: 6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tips[g.id] ?? g.subtitle,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.yellow.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 28)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Чем меньше ошибок и подсказок — тем больше звёзд! '
                    'Новый уровень открывается после прохождения предыдущего.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
