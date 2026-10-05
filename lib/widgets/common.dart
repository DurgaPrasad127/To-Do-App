import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeblock/core/theme/app_colors.dart';

/// Soft gradient background with two blurred colour glows.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final overlay = (p.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.bgTop, p.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: _Glow(color: AppColors.primary.o(p.dark ? 0.30 : 0.16), size: 300),
              ),
            ),
            Positioned(
              top: 280,
              left: -130,
              child: IgnorePointer(
                child: _Glow(color: AppColors.secondary.o(p.dark ? 0.16 : 0.15), size: 280),
              ),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.o(0)]),
      ),
    );
  }
}

/// Wraps any widget with a press-scale + haptic tap.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _set(false);
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? p.surface.o(p.dark ? 0.84 : 0.92) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border.o(0.55)),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientFor(color) : null,
            color: selected ? null : p.surface.o(0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [BoxShadow(color: color.o(0.32), blurRadius: 14, offset: const Offset(0, 6))]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: selected ? Colors.white : p.textMuted),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Color shadowColor;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.brandGradient,
    this.shadowColor = AppColors.primary,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Pressable(
          onTap: onPressed,
          scale: 0.97,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: shadowColor.o(0.38), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented pill selector (Month/Week, Light/Dark/System ...).
class SegmentedPill extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  const SegmentedPill({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: options[i],
                child: Pressable(
                  onTap: () => onChanged(i),
                  scale: 0.96,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: i == index ? AppColors.brandGradient : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: i == index
                          ? [BoxShadow(color: AppColors.primary.o(0.3), blurRadius: 12, offset: const Offset(0, 5))]
                          : const <BoxShadow>[],
                    ),
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: i == index ? Colors.white : p.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const ScreenTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  color: p.text,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14.5, color: p.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: p.text),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.primary.o(0.22), AppColors.primary.o(0.02)],
                    ),
                  ),
                ),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                    boxShadow: [BoxShadow(color: AppColors.primary.o(0.35), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: Icon(icon, color: Colors.white, size: 38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: p.textMuted, height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: 220,
              child: PrimaryButton(label: actionLabel!, icon: Icons.add_rounded, onPressed: onAction, height: 52),
            ),
          ],
        ],
      ),
    );
  }
}

/// Number that counts smoothly to its new value.
class AnimatedCount extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String suffix;
  const AnimatedCount({super.key, required this.value, required this.style, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Fade + rise entrance with a small index-based delay (staggered lists).
class Appear extends StatefulWidget {
  final int index;
  final Widget child;
  const Appear({super.key, required this.index, required this.child});

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final delay = math.min(widget.index, 8) * 55;
    if (delay == 0) {
      _c.forward();
    } else {
      _t = Timer(Duration(milliseconds: delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
        );
      },
    );
  }
}

/// Rebuilds its child every 30s and on app resume, handing over the current time.
class MinuteBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const MinuteBuilder({super.key, required this.builder});

  @override
  State<MinuteBuilder> createState() => _MinuteBuilderState();
}

class _MinuteBuilderState extends State<MinuteBuilder> with WidgetsBindingObserver {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

class AvatarBadge extends StatelessWidget {
  final String name;
  final int colorIndex;
  final double size;
  const AvatarBadge({super.key, required this.name, required this.colorIndex, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.taskColor(colorIndex).color;
    final initial = name.trim().isEmpty ? '' : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientFor(color),
        boxShadow: [BoxShadow(color: color.o(0.4), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: initial.isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: size * 0.55)
          : Text(
              initial,
              style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w800),
            ),
    );
  }
}

/// Rounded bottom-sheet surface with a drag handle.
class SheetSurface extends StatelessWidget {
  final Widget child;
  const SheetSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border.all(color: p.border.o(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.o(0.25), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 6),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Small coloured label used on cards.
class MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool strong;
  const MiniChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.o(strong ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text.o(0.85)),
          ),
        ],
      ),
    );
  }
}
