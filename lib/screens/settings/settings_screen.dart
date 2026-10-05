import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/core/utils/formatters.dart';
import 'package:timeblock/core/utils/ui_helpers.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/providers/task_provider.dart';
import 'package:timeblock/widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // UI order Light, Dark, System -> ThemeMode index 1, 2, 0
  static const _themeIdx = [1, 2, 0];

  Future<void> _pickDayTime(BuildContext context, bool start) async {
    final s = context.read<SettingsProvider>();
    final cur = start ? s.dayStartMin : s.dayEndMin;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    if (start) {
      if (m >= s.dayEndMin) {
        AppToast.error('Start of day must be earlier than end of day.');
        return;
      }
      s.setDayStart(m);
    } else {
      if (m <= s.dayStartMin) {
        AppToast.error('End of day must be later than start of day.');
        return;
      }
      s.setDayEnd(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<SettingsProvider>();
    final tp = context.watch<TaskProvider>();

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: [
          const ScreenTitle(title: 'Profile', subtitle: 'Make TimeBlock yours'),
          const SizedBox(height: 18),
          GlassCard(
            onTap: () => _editProfile(context),
            child: Row(
              children: [
                AvatarBadge(name: s.name, colorIndex: s.avatarColor, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name.isEmpty ? 'Add your name' : s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.bio.isEmpty ? 'Tap to add a short bio' : s.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: p.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, color: p.textFaint, size: 20),
              ],
            ),
          ),
          _section(context, 'APPEARANCE'),
          GlassCard(
            child: SegmentedPill(
              options: const ['Light', 'Dark', 'System'],
              index: _themeIdx.indexOf(s.themeIndex),
              onChanged: (i) => s.setThemeIndex(_themeIdx[i]),
            ),
          ),
          _section(context, 'PRODUCTIVITY'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _Row(
                  icon: Icons.flag_rounded,
                  color: AppColors.success,
                  title: 'Daily goal',
                  subtitle: 'Tasks to complete each day',
                  trailing: _Stepper(
                    value: s.dailyGoal,
                    onMinus: () => s.setDailyGoal(s.dailyGoal - 1),
                    onPlus: () => s.setDailyGoal(s.dailyGoal + 1),
                  ),
                ),
                _Row(
                  icon: Icons.wb_twilight_rounded,
                  color: AppColors.warning,
                  title: 'Start of day',
                  trailing: _TimeValue(Fmt.time(s.dayStartMin)),
                  onTap: () => _pickDayTime(context, true),
                ),
                _Row(
                  icon: Icons.nightlight_round,
                  color: AppColors.primary,
                  title: 'End of day',
                  trailing: _TimeValue(Fmt.time(s.dayEndMin)),
                  onTap: () => _pickDayTime(context, false),
                  last: true,
                ),
              ],
            ),
          ),
          _section(context, 'DATA'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _Row(
                  icon: Icons.ios_share_rounded,
                  color: AppColors.secondary,
                  title: 'Export data',
                  subtitle: 'Copy all tasks as JSON',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: tp.exportJson()));
                    AppToast.show('Copied ${tp.totalCount} tasks to clipboard',
                        icon: Icons.copy_rounded, iconColor: AppColors.secondary);
                  },
                ),
                _Row(
                  icon: Icons.cleaning_services_rounded,
                  color: AppColors.warning,
                  title: 'Clear completed tasks',
                  subtitle: '${tp.totalCompleted} completed',
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Clear completed tasks?',
                      message: 'All completed tasks and their history will be removed. This cannot be undone.',
                      confirmLabel: 'Clear',
                    );
                    if (!ok) return;
                    final n = await tp.clearCompleted();
                    AppToast.show('Removed $n completed tasks');
                  },
                ),
                if (tp.hasSamples)
                  _Row(
                    icon: Icons.auto_fix_off_rounded,
                    color: AppColors.primary,
                    title: 'Remove sample tasks',
                    subtitle: 'Delete the demo data from first launch',
                    onTap: () async {
                      final n = await tp.removeSamples();
                      AppToast.show('Removed $n sample tasks');
                    },
                  ),
                _Row(
                  icon: Icons.restart_alt_rounded,
                  color: AppColors.danger,
                  title: 'Reset app',
                  subtitle: 'Erase all tasks and settings',
                  last: true,
                  onTap: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Reset TimeBlock?',
                      message: 'Every task, setting and your history will be erased permanently.',
                      confirmLabel: 'Reset everything',
                    );
                    if (!ok) return;
                    await tp.resetAll();
                    await s.resetAll();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              'TimeBlock · v1.0.0\nEverything stays on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textFaint, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: p.textFaint),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheet(),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.border.o(0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.o(0.15), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.text)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 12.5, color: p.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing! else if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.textFaint),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(button: true, label: title, child: Pressable(onTap: onTap, scale: 0.98, child: row));
  }
}

class _TimeValue extends StatelessWidget {
  final String text;
  const _TimeValue(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _Stepper({required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget btn(IconData i, String label, VoidCallback f) => Semantics(
          button: true,
          label: label,
          child: Pressable(
            onTap: f,
            scale: 0.85,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: p.surfaceAlt, shape: BoxShape.circle),
              child: Icon(i, color: p.text, size: 20),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, 'Decrease goal', onMinus),
        SizedBox(
          width: 32,
          child: Center(
            child: Text('$value', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
          ),
        ),
        btn(Icons.add_rounded, 'Increase goal', onPlus),
      ],
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late int _avatar;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _name = TextEditingController(text: s.name);
    _bio = TextEditingController(text: s.bio);
    _avatar = s.avatarColor;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetSurface(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              Center(child: AvatarBadge(name: _name.text, colorIndex: _avatar, size: 76)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < AppColors.taskColors.length; i++)
                    Semantics(
                      button: true,
                      selected: _avatar == i,
                      label: '${AppColors.taskColors[i].name} avatar',
                      child: Pressable(
                        onTap: () => setState(() => _avatar = i),
                        scale: 0.88,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _avatar == i ? AppColors.taskColors[i].color : Colors.transparent,
                              width: 2.4,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.gradientFor(AppColors.taskColors[i].color),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontWeight: FontWeight.w700, color: p.text),
                decoration: inputDecoration(context, hint: 'Your name').copyWith(counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLength: 80,
                maxLines: 2,
                style: TextStyle(color: p.text),
                decoration: inputDecoration(context, hint: 'Short bio').copyWith(counterText: ''),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Save profile',
                icon: Icons.check_rounded,
                onPressed: () {
                  context.read<SettingsProvider>().setProfile(
                        newName: _name.text,
                        newBio: _bio.text,
                        newAvatar: _avatar,
                      );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
