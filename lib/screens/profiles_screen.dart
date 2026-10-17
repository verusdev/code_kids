import 'package:flutter/material.dart';

import '../services/achievements_service.dart';
import '../services/challenge_service.dart';
import '../services/daily_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Экран профилей детей: выбор активного профиля и управление ими.
///
/// В режиме выбора по тапу на карточку профиль переключается и экран
/// закрывается. В режиме управления по каждой карточке доступны
/// переименование и удаление.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileService _profiles = ProfileService.instance;

  /// Включён ли режим управления (переименование и удаление).
  bool _managing = false;

  /// Сумма звёзд по каждому профилю (ключ — идентификатор профиля).
  final Map<String, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  /// Подсчитать звёзды каждого профиля напрямую из хранилища.
  Future<void> _loadStars() async {
    final result = <String, int>{};
    for (final profile in _profiles.profiles) {
      result[profile.id] =
          await ProgressService.instance.totalStarsForProfile(profile.id);
    }
    if (!mounted) return;
    setState(() {
      _stars
        ..clear()
        ..addAll(result);
    });
  }

  /// Перечитать данные всех прогресс-сервисов после смены профиля.
  Future<void> _reloadServices() async {
    // Порядок важен: сначала медали, затем прогресс — чтобы при смене
    // профиля не показать поздравление за уже отмеченную медаль.
    await AchievementsService.instance.reload();
    await DailyService.instance.reload();
    await ProgressService.instance.reload();
    await ChallengeService.instance.reload();
  }

  Future<void> _select(Profile profile) async {
    final navigator = Navigator.of(context);
    if (profile.id != _profiles.currentId) {
      await _profiles.switchTo(profile.id);
      await _reloadServices();
    }
    navigator.pop();
  }

  Future<void> _addProfile() async {
    final result = await showDialog<({String name, String emoji})>(
      context: context,
      builder: (context) => const _ProfileEditDialog(
        title: 'Новый профиль',
        submitLabel: 'Добавить',
      ),
    );
    if (result == null || !mounted) return;
    _profiles.add(result.name, result.emoji);
    await _loadStars();
  }

  Future<void> _rename(Profile profile) async {
    final result = await showDialog<({String name, String emoji})>(
      context: context,
      builder: (context) => _ProfileEditDialog(
        title: 'Переименовать',
        submitLabel: 'Сохранить',
        initialName: profile.name,
        initialEmoji: profile.emoji,
      ),
    );
    if (result == null || !mounted) return;
    await _profiles.rename(profile.id, name: result.name, emoji: result.emoji);
  }

  Future<void> _delete(Profile profile) async {
    if (_profiles.profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нельзя удалить единственный профиль 🙂'),
        ),
      );
      return;
    }
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: Text(
          'Прогресс профиля «${profile.name}» будет удалён. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final wasCurrent = profile.id == _profiles.currentId;
    final removed = await _profiles.remove(profile.id);
    if (!mounted) return;
    if (removed && wasCurrent) {
      // Удалили текущий профиль — сервисы переключились на первый.
      await _reloadServices();
    }
    await _loadStars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_managing ? '⚙️ Настройка профилей' : 'Кто играет?'),
      ),
      body: ListenableBuilder(
        listenable: _profiles,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  _managing
                      ? 'Здесь можно переименовать или удалить профиль'
                      : 'Нажми на карточку, чтобы выбрать героя',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: _managing ? 0.85 : 1.0,
                  children: [
                    for (final profile in _profiles.profiles)
                      _ProfileCard(
                        profile: profile,
                        stars: _stars[profile.id] ?? 0,
                        current: profile.id == _profiles.currentId,
                        managing: _managing,
                        onSelect: () => _select(profile),
                        onRename: () => _rename(profile),
                        onDelete: () => _delete(profile),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addProfile,
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('➕ Добавить профиль'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.teal,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _managing = !_managing),
                          icon: Icon(_managing
                              ? Icons.check_rounded
                              : Icons.settings_rounded),
                          label: Text(_managing ? '✅ Готово' : '⚙️ Настроить'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.purple,
                            side: const BorderSide(
                                color: AppTheme.purple, width: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Карточка профиля: аватар, имя и сумма звёзд.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.stars,
    required this.current,
    required this.managing,
    this.onSelect,
    this.onRename,
    this.onDelete,
  });

  final Profile profile;
  final int stars;
  final bool current;

  /// Включён ли режим управления (показываем кнопки вместо выбора).
  final bool managing;

  final VoidCallback? onSelect;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: managing ? null : onSelect,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: current ? AppTheme.purple : const Color(0xFFE6E9F0),
              width: current ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile.emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 4),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '⭐ $stars',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
              if (current && !managing) ...[
                const SizedBox(height: 2),
                const Text(
                  'Сейчас играет',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.purple,
                  ),
                ),
              ],
              if (managing) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Переименовать',
                        child: IconButton(
                          onPressed: onRename,
                          icon: const Text('✏️',
                              style: TextStyle(fontSize: 20)),
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Tooltip(
                        message: 'Удалить',
                        child: IconButton(
                          onPressed: onDelete,
                          icon: const Text('🗑️',
                              style: TextStyle(fontSize: 20)),
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Диалог добавления/переименования профиля: имя + (для переименования)
/// выбор аватара из пресета эмодзи.
///
/// Для добавления [initialEmoji] не задан — выбор эмодзи скрыт.
class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.title,
    required this.submitLabel,
    this.initialName = '',
    this.initialEmoji,
  });

  final String title;
  final String submitLabel;
  final String initialName;

  /// Текущий аватар; если не задан — эмодзи не показываем (режим добавления).
  final String? initialEmoji;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _controller;
  late String _emoji;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _emoji = widget.initialEmoji ?? kProfileEmojis.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введи имя 🙂');
      return;
    }
    Navigator.of(context).pop((name: name, emoji: _emoji));
  }

  @override
  Widget build(BuildContext context) {
    final pickEmoji = widget.initialEmoji != null;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 20,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Имя',
              hintText: 'Например, Маша',
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (pickEmoji) ...[
            const SizedBox(height: 8),
            const Text(
              'Выбери героя',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final emoji in kProfileEmojis)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 20)),
                    selected: _emoji == emoji,
                    onSelected: (_) => setState(() => _emoji = emoji),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
