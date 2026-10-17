import 'package:flutter/material.dart';

import '../../services/turtle_gallery_service.dart';
import '../../widgets/turtle_canvas.dart';

/// Галерея сохранённых рисунков черепашки (из Песочницы).
///
/// Сетка плиток с превью; тап — полноэкранный просмотр с анимацией
/// появления линий; у каждой плитки есть удаление с подтверждением.
class TurtleGalleryScreen extends StatelessWidget {
  const TurtleGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = TurtleGalleryService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('🖼 Галерея рисунков')),
      body: ListenableBuilder(
        listenable: gallery,
        builder: (context, _) {
          final drawings = gallery.drawings;
          if (drawings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Пока пусто — нарисуй что-нибудь в Песочнице! 🎨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B94A7),
                    height: 1.4,
                  ),
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: drawings.length,
            itemBuilder: (context, index) => _DrawingTile(
              drawing: drawings[index],
              onDelete: () => _confirmDelete(context, drawings[index]),
            ),
          );
        },
      ),
    );
  }

  /// Подтверждение удаления рисунка.
  Future<void> _confirmDelete(BuildContext context, TurtleDrawing drawing) async {
    final gallery = TurtleGalleryService.instance;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Удалить рисунок?',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '«${drawing.name}» будет стёрт навсегда.',
          style: const TextStyle(fontSize: 16, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (sure == true) await gallery.remove(drawing.id);
  }
}

/// Плитка одного рисунка: превью, имя, дата и кнопка удаления.
class _DrawingTile extends StatelessWidget {
  const _DrawingTile({required this.drawing, required this.onDelete});

  final TurtleDrawing drawing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _TurtleViewerScreen(drawing: drawing),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TurtleCanvas(
                  segments: drawing.segments,
                  height: double.infinity,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drawing.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatDate(drawing.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Удалить рисунок ${drawing.name}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.grey.shade500,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

/// Полноэкранный просмотр рисунка: линии появляются с анимацией.
class _TurtleViewerScreen extends StatelessWidget {
  const _TurtleViewerScreen({required this.drawing});

  final TurtleDrawing drawing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🖼 ${drawing.name}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: TurtleCanvas(
              segments: drawing.segments,
              height: 480,
            ),
          ),
        ),
      ),
    );
  }
}
