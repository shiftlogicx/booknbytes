import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Genuine luxury confirmation animation with expanding ripple rings,
/// an elastic checkmark badge, and crisp vector sparkle particles (no emojis).
class GenuineConfirmationAnimation extends StatefulWidget {
  final double size;
  final VoidCallback? onComplete;

  const GenuineConfirmationAnimation({
    super.key,
    this.size = 120,
    this.onComplete,
  });

  @override
  State<GenuineConfirmationAnimation> createState() => _GenuineConfirmationAnimationState();
}

/// Backwards compatibility alias for older references
typedef EmojiCelebrationBurst = GenuineConfirmationAnimation;

class _GenuineConfirmationAnimationState extends State<GenuineConfirmationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_VectorParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final random = math.Random();
    const particleColors = [
      Color(0xFF10B981), // Emerald
      Color(0xFF34D399), // Mint
      Color(0xFFF59E0B), // Amber Gold
      Color(0xFFFBBF24), // Light Gold
      Color(0xFF6EE7B7), // Light Emerald
    ];

    _particles = List.generate(14, (i) {
      final angle = (i * (2 * math.pi / 14)) + (random.nextDouble() * 0.3 - 0.15);
      final distance = 48.0 + random.nextDouble() * 38.0;
      final size = 4.0 + random.nextDouble() * 4.0;
      final isDiamond = i.isEven;
      return _VectorParticle(
        color: particleColors[i % particleColors.length],
        dx: math.cos(angle) * distance,
        dy: math.sin(angle) * distance - 8,
        size: size,
        isDiamond: isDiamond,
        rotation: random.nextDouble() * math.pi,
      );
    });

    _controller.forward().then((_) {
      if (widget.onComplete != null && mounted) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        // Ripples
        final ripple1Progress = math.min(1.0, progress * 1.5);
        final ripple1Scale = 0.8 + (ripple1Progress * 0.9);
        final ripple1Opacity = (1.0 - ripple1Progress).clamp(0.0, 0.45);

        final ripple2Progress = math.max(0.0, (progress - 0.15) * 1.4);
        final ripple2Scale = 0.6 + (ripple2Progress * 1.0);
        final ripple2Opacity = (1.0 - ripple2Progress).clamp(0.0, 0.35);

        // Central Badge Elastic Scale
        final badgeScale = Curves.elasticOut.transform(math.min(1.0, progress * 1.25));

        // Particle Burst
        final particleProgress = Curves.easeOutCubic.transform(math.min(1.0, progress * 1.3));
        final particleFade = progress > 0.65 ? ((1.0 - progress) / 0.35).clamp(0.0, 1.0) : 1.0;

        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ripple Ring 1
              if (ripple1Opacity > 0.01)
                Transform.scale(
                  scale: ripple1Scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: ripple1Opacity),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),

              // Outer Ripple Ring 2
              if (ripple2Opacity > 0.01)
                Transform.scale(
                  scale: ripple2Scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: ripple2Opacity),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Central Checkmark Badge
              Transform.scale(
                scale: badgeScale,
                child: Container(
                  width: widget.size * 0.68,
                  height: widget.size * 0.68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      radius: 0.9,
                      colors: [
                        Color(0xFF34D399), // Light emerald
                        Color(0xFF059669), // Rich emerald
                        Color(0xFF047857), // Deep emerald
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),

              // Vector Sparkle Particles (No Emojis)
              ..._particles.map((p) {
                final currentDx = p.dx * particleProgress;
                final currentDy = p.dy * particleProgress;
                final currentScale = (particleProgress < 0.2 ? particleProgress * 5 : 1.0);

                return Transform.translate(
                  offset: Offset(currentDx, currentDy),
                  child: Transform.rotate(
                    angle: p.rotation + (particleProgress * 0.8),
                    child: Transform.scale(
                      scale: currentScale,
                      child: Opacity(
                        opacity: particleFade,
                        child: p.isDiamond
                            ? Container(
                                width: p.size,
                                height: p.size,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              )
                            : Container(
                                width: p.size,
                                height: p.size,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _VectorParticle {
  final Color color;
  final double dx;
  final double dy;
  final double size;
  final bool isDiamond;
  final double rotation;

  _VectorParticle({
    required this.color,
    required this.dx,
    required this.dy,
    required this.size,
    required this.isDiamond,
    required this.rotation,
  });
}
