import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/widgets/common.dart';

/// Round checkbox with a springy tick animation (44dp touch target).
class AnimatedCheck extends StatelessWidget {
  final bool checked;
  final Color color;
  final VoidCallback onTap;
  final String label;
  final double size;

  const AnimatedCheck({
    super.key,
    required this.checked,
    required this.color,
    required this.onTap,
    required this.label,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.82,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: checked ? AppColors.gradientFor(color) : null,
                border: Border.all(color: checked ? Colors.transparent : color.o(0.75), width: 2.2),
                boxShadow: checked
                    ? [BoxShadow(color: color.o(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                    : const <BoxShadow>[],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.elasticOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: checked
                    ? Icon(Icons.check_rounded, key: const ValueKey('on'), size: 19, color: Colors.white)
                    : const SizedBox.shrink(key: ValueKey('off')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
