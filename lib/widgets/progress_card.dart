import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/widgets/common.dart';

class ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final int goal;

  const ProgressCard({super.key, required this.done, required this.total, required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : done / total;
    final pct = (percent * 100).round();
    final goalText = total == 0
        ? 'Plan your first block'
        : (done >= goal ? 'Daily goal reached 🎯' : '${goal - done} more to hit your goal');

    return Semantics(
      container: true,
      label: '$done of $total tasks completed, $pct percent',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.primary.o(0.38), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(right: -40, top: -50, child: _bubble(170, 0.10)),
              Positioned(left: -30, bottom: -60, child: _bubble(150, 0.08)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY PROGRESS',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: Colors.white.o(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedCount(
                                  value: done,
                                  style: const TextStyle(
                                    fontSize: 44,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5, left: 4),
                                  child: Text(
                                    '/ $total',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.o(0.78),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'tasks completed',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.o(0.9)),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.o(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              goalText,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: percent),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => CustomPaint(
                          painter: _RingPainter(progress: v, track: Colors.white.o(0.22), color: Colors.white),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedCount(
                                  value: pct,
                                  suffix: '%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'done',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.o(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.o(opacity)),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;
  const _RingPainter({required this.progress, required this.track, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress <= 0.001) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
