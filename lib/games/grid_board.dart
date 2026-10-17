import 'dart:math';

import 'package:flutter/material.dart';

/// Препятствие-«кирпич» на поле.
const String kWallEmoji = '🧱';

/// Клетчатое игровое поле с сеткой, стенами и анимированными спрайтами.
///
/// Используется играми «Робот-Лабиринт» и «Собери звёзды».
class GridBoard extends StatelessWidget {
  const GridBoard({
    super.key,
    required this.cols,
    required this.rows,
    required this.walls,
    this.sprites = const [],
    this.props = const [],
    this.showLabels = false,
  });

  final int cols;
  final int rows;

  /// Множество стен: индекс клетки = y * cols + x.
  final Set<int> walls;
  final List<BoardSprite> sprites;

  /// Необязательные предметы на клетках (ключи, двери, телепорты и т.п.).
  ///
  /// По умолчанию список пуст — старые игры работают без изменений.
  final List<BoardProp> props;
  final bool showLabels;

  bool isWall(int x, int y) => walls.contains(y * cols + x);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = min(constraints.maxWidth / cols, constraints.maxHeight / rows);
        final boardW = cell * cols;
        final boardH = cell * rows;

        return Center(
          child: Container(
            width: boardW,
            height: boardH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Клетки.
                for (int y = 0; y < rows; y++)
                  for (int x = 0; x < cols; x++)
                    Positioned(
                      left: x * cell,
                      top: y * cell,
                      width: cell,
                      height: cell,
                      child: Container(
                        decoration: BoxDecoration(
                          color: (x + y).isEven
                              ? const Color(0xFFF6F3FF)
                              : const Color(0xFFEDE9FE),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isWall(x, y)
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.all(cell * 0.12),
                                  child: const Text(
                                    kWallEmoji,
                                    style: TextStyle(fontSize: 30),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                // Предметы на клетках (ключи, двери, телепорты и т.п.).
                // Рисуются под спрайтами и не перехватывают нажатия.
                for (final p in props)
                  Positioned(
                    left: p.x * cell,
                    top: p.y * cell,
                    width: cell,
                    height: cell,
                    child: IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.all(cell * 0.10),
                        child: Opacity(
                          opacity: p.opacity.clamp(0.0, 1.0),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: p.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Спрайты (робот, звёзды, флажок).
                for (final s in sprites)
                  AnimatedPositioned(
                    key: ValueKey(s.id),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    left: s.x * cell,
                    top: s.y * cell,
                    width: cell,
                    height: cell,
                    child: Center(child: s.child),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Спрайт на поле: идентификатор нужен для анимации позиции.
class BoardSprite {
  const BoardSprite({
    required this.id,
    required this.x,
    required this.y,
    required this.child,
  });

  final Object id;
  final int x;
  final int y;
  final Widget child;
}

/// Статичный предмет на клетке поля: ключ, дверь, телепорт и т.п.
///
/// В отличие от [BoardSprite] не анимируется и рисуется под спрайтами.
/// Идентификатор нужен только для стабильной отрисовки списка.
class BoardProp {
  const BoardProp({
    required this.id,
    required this.x,
    required this.y,
    required this.child,
    this.opacity = 1.0,
  });

  final Object id;
  final int x;
  final int y;
  final Widget child;

  /// Прозрачность (например, для «погасшей» уже собранной вещи).
  final double opacity;
}

/// Помощник для вычисления индексов клеток.
class BoardGrid {
  const BoardGrid(this.cols);

  final int cols;

  int key(int x, int y) => y * cols + x;
}
