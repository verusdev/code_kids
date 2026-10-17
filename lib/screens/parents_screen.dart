import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../achievements/achievements.dart';
import '../models/game_models.dart';
import '../python/lessons/python_course.dart';
import '../services/achievements_service.dart';
import '../services/challenge_service.dart';
import '../services/daily_service.dart';
import '../services/playtime_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Экран «Родителям»: общая картина успехов ребёнка и советы.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('👨‍👩‍👧 Родителям')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          progress,
          DailyService.instance,
          PlaytimeService.instance,
        ]),
        builder: (context, _) {
          final all = [...kGames, ...kSystemGames, kPythonCourse];

          var earned = 0;
          var maxStars = 0;
          var passed = 0;
          var levels = 0;
          for (final game in all) {
            earned += progress.totalStars(game.id);
            maxStars += game.levelCount * 3;
            levels += game.levelCount;
            for (var i = 0; i < game.levelCount; i++) {
              if (progress.starsFor(game.id, i) > 0) passed++;
            }
          }

          final snapshot = currentSnapshot();
          final medals = kAchievements
              .where((a) => a.isUnlocked(snapshot))
              .length;
          final daily = DailyService.instance;
          final playtime = PlaytimeService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SummaryCard(
                earned: earned,
                maxStars: maxStars,
                passed: passed,
                levels: levels,
                medals: medals,
                streak: daily.streak,
                bestStreak: daily.bestStreak,
                timeToday: playtime.todaySeconds,
                timeTotal: playtime.totalSeconds,
              ),
              const SizedBox(height: 16),
              _SectionTitle('📊 Прогресс по разделам'),
              for (final game in all)
                _GameProgressRow(
                  game: game,
                  stars: progress.totalStars(game.id),
                  passedLevels: List.generate(
                    game.levelCount,
                    (i) => progress.starsFor(game.id, i),
                  ).where((v) => v > 0).length,
                ),
              const SizedBox(height: 16),
              _SectionTitle('🧭 Отчёт: сильные и слабые темы'),
              _TopicsCard(all: all, progress: progress),
              const SizedBox(height: 16),
              _SectionTitle('💡 Как помочь ребёнку'),
              const _AdviceCard(),
              const SizedBox(height: 16),
              _SectionTitle('💾 Экспорт / импорт прогресса'),
              const _BackupTile(),
              const SizedBox(height: 16),
              _SectionTitle('🔧 Настройки'),
              _ResetTile(progress: progress),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.earned,
    required this.maxStars,
    required this.passed,
    required this.levels,
    required this.medals,
    required this.streak,
    required this.bestStreak,
    required this.timeToday,
    required this.timeTotal,
  });

  final int earned;
  final int maxStars;
  final int passed;
  final int levels;
  final int medals;
  final int streak;
  final int bestStreak;
  final int timeToday;
  final int timeTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.purple, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Успехи ребёнка',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Stat('⭐', 'Звёзды', '$earned из $maxStars'),
              _Stat('🏁', 'Уровни', '$passed из $levels'),
              _Stat('🏅', 'Медали', '$medals из ${kAchievements.length}'),
              _Stat('🔥', 'Серия', '$streak дн.'),
              _Stat('🏆', 'Рекорд', '$bestStreak дн.'),
              _Stat('⏱️', 'Сегодня', PlaytimeService.formatDuration(timeToday)),
              _Stat('⌛', 'Всего', PlaytimeService.formatDuration(timeTotal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.label, this.value);

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $label',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameProgressRow extends StatelessWidget {
  const _GameProgressRow({
    required this.game,
    required this.stars,
    required this.passedLevels,
  });

  final GameInfo game;
  final int stars;
  final int passedLevels;

  @override
  Widget build(BuildContext context) {
    final maxStars = game.levelCount * 3;
    final value = maxStars == 0 ? 0.0 : (stars / maxStars).clamp(0.0, 1.0);
    final color = AppTheme.gameColors[game.id] ?? AppTheme.purple;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$stars / $maxStars ⭐',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Пройдено уровней: $passedLevels из ${game.levelCount}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard({required this.all, required this.progress});

  final List<GameInfo> all;
  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    final strong = <GameInfo>[];
    final weak = <GameInfo>[];
    final untouched = <GameInfo>[];

    for (final game in all) {
      final maxStars = game.levelCount * 3;
      if (maxStars == 0) continue;
      final ratio = progress.totalStars(game.id) / maxStars;
      final started = progress.totalStars(game.id) > 0;
      if (!started) {
        untouched.add(game);
      } else if (ratio >= 0.6) {
        strong.add(game);
      } else if (ratio < 0.35) {
        weak.add(game);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topicLine(
            '💚 Сильные темы',
            strong,
            'Здесь ребёнок уверенно справляется — можно похвалить!',
          ),
          const SizedBox(height: 10),
          _topicLine(
            '🎯 Стоит потренировать',
            weak,
            'Эти разделы даются сложнее — помогите с ними.',
          ),
          const SizedBox(height: 10),
          _topicLine(
            '🌱 Ещё не начаты',
            untouched,
            'Разделы, которые ребёнок пока не открывал.',
          ),
        ],
      ),
    );
  }

  Widget _topicLine(String title, List<GameInfo> games, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 6),
        if (games.isEmpty)
          const Text('—', style: TextStyle(color: Colors.black45))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in games)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Text(g.emoji),
                  label: Text(g.title),
                ),
            ],
          ),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('⏱️', 'Занимайтесь по 10–15 минут в день — коротко и регулярно.'),
      ('🤝', 'Если не получается — не спешите подсказывать, дайте подумать.'),
      ('🗣️', 'Просите ребёнка объяснить, что делает его программа.'),
      ('🎉', 'Хвалите за старание, а не только за звёзды.'),
      ('🔁', 'Повторять пройденные уровни полезно — это закрепление.'),
      ('💬', 'Ошибки в коде — нормально: это повод посмотреть консоль вместе.'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip.$2,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResetTile extends StatelessWidget {
  const _ResetTile({required this.progress});

  final ProgressService progress;

  Future<void> _confirmReset(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить весь прогресс?'),
        content: const Text(
          'Звёзды, медали и серия будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await progress.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Прогресс сброшен')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Сбросить прогресс'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.pink,
          side: const BorderSide(color: AppTheme.pink, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Блок «Экспорт / импорт прогресса»: перенос прогресса между устройствами
/// через буфер обмена (без интернета и сторонних библиотек).
class _BackupTile extends StatelessWidget {
  const _BackupTile();

  /// Собрать JSON-бэкап прогресса текущего профиля.
  String _buildBackup() {
    final profile = ProfileService.instance.current;
    return jsonEncode({
      'profile': {'name': profile.name, 'emoji': profile.emoji},
      'progress': ProgressService.instance.exportData(),
      'achievements': AchievementsService.instance.exportData(),
      'daily': DailyService.instance.exportData(),
      'challenge': ChallengeService.instance.exportData(),
    });
  }

  /// Проверить, что распакованное JSON-сообщение похоже на сохранённый
  /// прогресс: есть карта `progress` со списками чисел.
  bool _looksLikeBackup(Map<String, dynamic> map) {
    final progress = map['progress'];
    if (progress is! Map) return false;
    for (final value in progress.values) {
      if (value is! List) return false;
      for (final item in value) {
        if (item is! num) return false;
      }
    }
    return true;
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: _buildBackup()));
      messenger.showSnackBar(const SnackBar(content: Text('Скопировано!')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не получилось скопировать 😔')),
      );
    }
  }

  Future<void> _paste(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportDialog(),
    );
    if (text == null) return; // Отменили.
    if (text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Буфер обмена пуст — сначала нажми «Скопировать»'),
        ),
      );
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map<String, dynamic> || !_looksLikeBackup(decoded)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не похоже на сохранённый прогресс')),
      );
      return;
    }

    final progress = decoded['progress'];
    if (progress is Map) {
      await ProgressService.instance.importData(
        Map<String, dynamic>.from(progress),
      );
    }
    final achievements = decoded['achievements'];
    if (achievements is List) {
      await AchievementsService.instance.importData(
        achievements.whereType<String>().toList(),
      );
    }
    final daily = decoded['daily'];
    if (daily is Map) {
      await DailyService.instance.importData(Map<String, dynamic>.from(daily));
    }
    final challenge = decoded['challenge'];
    if (challenge is num) {
      await ChallengeService.instance.importData(challenge.toInt());
    }
    // Перечитываем всё с диска, чтобы UI точно показывал восстановленное.
    await ProgressService.instance.reload();
    await AchievementsService.instance.reload();
    await DailyService.instance.reload();
    await ChallengeService.instance.reload();

    messenger.showSnackBar(const SnackBar(content: Text('Готово!')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E9F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Прогресс можно скопировать на другое устройство: нажмите '
            '«Скопировать прогресс», затем на новом устройстве '
            '«Вставить и восстановить».',
            style: TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Скопировать прогресс'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sky,
                side: const BorderSide(color: AppTheme.sky, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _paste(context),
              icon: const Icon(Icons.paste_rounded),
              label: const Text('Вставить и восстановить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.teal,
                side: const BorderSide(color: AppTheme.teal, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог вставки бэкапа: большое поле для JSON из буфера обмена.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Вставь сохранённый прогресс'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          maxLines: 8,
          minLines: 4,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Вставь сюда скопированный текст',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Восстановить'),
        ),
      ],
    );
  }
}
