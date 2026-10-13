import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Направление на клетчатом поле.
enum Direction {
  up,
  right,
  down,
  left;

  int get dx => switch (this) {
        Direction.up => 0,
        Direction.right => 1,
        Direction.down => 0,
        Direction.left => -1,
      };

  int get dy => switch (this) {
        Direction.up => -1,
        Direction.right => 0,
        Direction.down => 1,
        Direction.left => 0,
      };

  /// Поворот налево (против часовой стрелки).
  Direction get turnLeft => switch (this) {
        Direction.up => Direction.left,
        Direction.left => Direction.down,
        Direction.down => Direction.right,
        Direction.right => Direction.up,
      };

  /// Поворот направо (по часовой стрелке).
  Direction get turnRight => switch (this) {
        Direction.up => Direction.right,
        Direction.right => Direction.down,
        Direction.down => Direction.left,
        Direction.left => Direction.up,
      };

  IconData get icon => switch (this) {
        Direction.up => Icons.arrow_upward_rounded,
        Direction.right => Icons.arrow_forward_rounded,
        Direction.down => Icons.arrow_downward_rounded,
        Direction.left => Icons.arrow_back_rounded,
      };
}

/// Описание мини-игры для главного экрана.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.levelCount,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final int levelCount;

  Color get color => AppTheme.gameColors[id] ?? AppTheme.purple;
}

/// Реестр всех игр приложения.
const List<GameInfo> kGames = [
  GameInfo(
    id: 'maze',
    title: 'Робот-Лабиринт',
    subtitle: 'Составь программу для робота',
    emoji: '🤖',
    levelCount: 15,
  ),
  GameInfo(
    id: 'stars',
    title: 'Собери звёзды',
    subtitle: 'Складывай путь из блоков',
    emoji: '⭐',
    levelCount: 15,
  ),
  GameInfo(
    id: 'pattern',
    title: 'Найди закономерность',
    subtitle: 'Что идёт дальше?',
    emoji: '🔁',
    levelCount: 15,
  ),
  GameInfo(
    id: 'odd',
    title: 'Лишний элемент',
    subtitle: 'Кто здесь лишний?',
    emoji: '🔍',
    levelCount: 15,
  ),
  GameInfo(
    id: 'steps',
    title: 'Порядок действий',
    subtitle: 'Расставь шаги по порядку',
    emoji: '📋',
    levelCount: 15,
  ),
  GameInfo(
    id: 'blocks',
    title: 'Программируй блоками',
    subtitle: 'Циклы и условия',
    emoji: '📦',
    levelCount: 15,
  ),
  GameInfo(
    id: 'pixel',
    title: 'Пиксель-арт',
    subtitle: 'Рисуем программами',
    emoji: '🎨',
    levelCount: 15,
  ),
];

/// Тренажёры раздела «Системное мышление» (отдельный блок на главном экране).
const List<GameInfo> kSystemGames = [
  GameInfo(
    id: 'parts',
    title: 'Части и целое',
    subtitle: 'Из чего состоит система?',
    emoji: '🧩',
    levelCount: 15,
  ),
  GameInfo(
    id: 'causes',
    title: 'Цепочка причин',
    subtitle: 'Что случится дальше?',
    emoji: '🔗',
    levelCount: 15,
  ),
  GameInfo(
    id: 'rules',
    title: 'Умные правила',
    subtitle: 'Если — то: как система решает',
    emoji: '⚙️',
    levelCount: 15,
  ),
];

GameInfo gameById(String id) =>
    [...kGames, ...kSystemGames].firstWhere((g) => g.id == id);
