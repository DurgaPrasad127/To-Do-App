import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeblock/core/theme/app_colors.dart';
import 'package:timeblock/providers/settings_provider.dart';
import 'package:timeblock/widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _index = 0;

  static const _titles = ['Plan your day.', 'Block your time.', 'Track your progress.'];
  static const _bodies = [
    'Capture tasks in seconds and decide what matters most today.',
    'Give every task a start and end time and watch your day take shape on a live timeline.',
    'Complete tasks, keep your full history and see how consistent you are every week.',
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _finish() => context.read<SettingsProvider>().completeOnboarding();

  Widget _art(int i) {
    switch (i) {
      case 0:
        return const _PlanArt();
      case 1:
        return const _BlockArt();
      default:
        return const _TrackArt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: AnimatedOpacity(
                    opacity: _index < 2 ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Semantics(
                      button: true,
                      label: 'Skip onboarding',
                      child: Pressable(
                        onTap: _index < 2 ? _finish : null,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: Text('Skip',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: 3,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    return AnimatedBuilder(
                      animation: _pc,
                      builder: (context, _) {
                        double page = _index.toDouble();
                        if (_pc.hasClients && _pc.position.haveDimensions) {
                          page = _pc.page ?? page;
                        }
                        var delta = (page - i).abs();
                        if (delta > 1) delta = 1;
                        return Opacity(
                          opacity: 1 - delta * 0.7,
                          child: Transform.scale(
                            scale: 1 - delta * 0.1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: SizedBox(width: 300, height: 300, child: _art(i)),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _titles[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                      height: 1.1,
                                      color: p.text,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _bodies[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, height: 1.5, color: p.textMuted),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 30 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: i == _index ? AppColors.brandGradient : null,
                        color: i == _index ? null : p.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: PrimaryButton(
                  label: _index == 2 ? 'Get started' : 'Next',
                  icon: _index == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── illustrations (pure shapes) ─────────────────────────

class _Backdrop extends StatelessWidget {
  final Widget child;
  const _Backdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppColors.primary.o(0.26), AppColors.primary.o(0.02)]),
          ),
        ),
        child,
      ],
    );
  }
}

class _MiniTask extends StatelessWidget {
  final Color color;
  final double width;
  final bool done;
  const _MiniTask({required this.color, required this.width, this.done = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.o(0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(gradient: AppColors.gradientFor(color), borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 8, width: 90, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 6, width: 54, decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? AppColors.successGradient : null,
              border: done ? null : Border.all(color: color.o(0.7), width: 2),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}

class _PlanArt extends StatelessWidget {
  const _PlanArt();

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 52, left: 14, child: Transform.rotate(angle: -0.06, child: const _MiniTask(color: Color(0xFF7C6CFF), width: 230))),
          Positioned(top: 120, right: 6, child: Transform.rotate(angle: 0.05, child: const _MiniTask(color: Color(0xFF22B8E6), width: 230, done: true))),
          Positioned(top: 190, left: 24, child: Transform.rotate(angle: -0.03, child: const _MiniTask(color: Color(0xFFEC4899), width: 220))),
        ],
      ),
    );
  }
}

class _BlockArt extends StatelessWidget {
  const _BlockArt();

  Widget _block(Color c, double h, double w) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: AppColors.gradientFor(c),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.o(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Backdrop(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            for (var i = 0; i < 4; i++)
              Positioned(
                top: 18.0 + i * 62,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Text('${9 + i * 2}:00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textFaint)),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 1.5, color: p.border)),
                  ],
                ),
              ),
            Positioned(top: 26, left: 52, child: _block(const Color(0xFF7C6CFF), 74, 170)),
            Positioned(top: 112, left: 52, child: _block(const Color(0xFF22C55E), 44, 120)),
            Positioned(top: 112, left: 178, child: _block(const Color(0xFFFB8A3C), 44, 44)),
            Positioned(top: 168, left: 52, child: _block(const Color(0xFFEC4899), 66, 170)),
            Positioned(
              top: 152,
              left: 44,
              right: 0,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.nowRed, shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(height: 2, color: AppColors.nowRed)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackArt extends StatelessWidget {
  const _TrackArt();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const heights = [0.45, 0.7, 0.55, 0.9, 0.65, 0.8, 0.5];
    return _Backdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 0.72),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                painter: _Ring(v, p.border),
                child: Center(
                  child: Text('${(v * 100).round()}%',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.text)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in heights)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 18,
                    height: 60 * h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(7),
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

class _Ring extends CustomPainter {
  final double progress;
  final Color track;
  const _Ring(this.progress, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [AppColors.primary, AppColors.secondary, AppColors.primary],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.progress != progress || old.track != track;
}
