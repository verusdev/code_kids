import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/daily_service.dart';
import '../services/progress_service.dart';
import 'blocks/blocks_game.dart';
import 'causes/causes_game.dart';
import 'collect_stars/collect_stars_game.dart';
import 'odd_one_out/odd_one_out_game.dart';
import 'parts/parts_game.dart';
import 'pattern/pattern_game.dart';
import 'pixel/pixel_game.dart';
import 'robot_maze/robot_maze_game.dart';
import 'rules/rules_game.dart';
import 'steps_order/steps_order_game.dart';

/// Возвращает игровой экран для нужной игры и уровня.
///
/// [onFinished] вызывается, когда ребёнок прошёл уровень, с количеством звёзд.
Widget buildGameScreen({
  required String gameId,
  required int levelIndex,
  required void Function(int stars) onFinished,
}) {
  switch (gameId) {
    case 'maze':
      return RobotMazeGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'stars':
      return CollectStarsGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'pattern':
      return PatternGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'odd':
      return OddOneOutGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'steps':
      return StepsOrderGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'blocks':
      return BlocksGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'pixel':
      return PixelGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'parts':
      return PartsGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'causes':
      return CausesGame(levelIndex: levelIndex, onFinished: onFinished);
    case 'rules':
      return RulesGame(levelIndex: levelIndex, onFinished: onFinished);
    default:
      return Scaffold(
        appBar: AppBar(title: const Text('Игра не найдена')),
        body: const Center(child: Text('Такой игры пока нет 🙂')),
      );
  }
}

/// Запускает уровень и записывает результат в прогресс.
Future<void> startLevel(
  BuildContext context,
  GameInfo game,
  int levelIndex,
) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => buildGameScreen(
        gameId: game.id,
        levelIndex: levelIndex,
        onFinished: (stars) {
          ProgressService.instance
              .record(game.id, levelIndex, stars, game.levelCount);
          DailyService.instance
              .recordLevel(gameId: game.id, stars: stars);
        },
      ),
    ),
  );
}
