import 'dart:math' as math;
import 'package:flutter/material.dart';

class EmojiCelebrationBurst extends StatefulWidget {
  final List<String> emojis;
  final double size;
  final VoidCallback? onComplete;

  const EmojiCelebrationBurst({
    super.key,
    this.emojis = const ['🥳', '🎉', '🍽️', '✨', '👨‍🍳', '🥂', '🔥'],
    this.size = 120,
    this.onComplete,
  });

  @override
  State<EmojiCelebrationBurst> createState() => _EmojiCelebrationBurstState();
}

class _EmojiCelebrationBurstState extends State<EmojiCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    final random = math.Random();
    _particles = List.generate(widget.emojis.length, (i) {
      final angle = (i * (2 * math.pi / widget.emojis.length)) + (random.nextDouble() * 0.4 - 0.2);
      final distance = 45.0 + random.nextDouble() * 40.0;
      final scale = 0.8 + random.nextDouble() * 0.5;
      final rotation = (random.nextDouble() - 0.5) * 1.5;
      return _Particle(
        emoji: widget.emojis[i % widget.emojis.length],
        dx: math.cos(angle) * distance,
        dy: math.sin(angle) * distance - 20, // bias slightly upwards
        scale: scale,
        rotation: rotation,
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
        // Ease out back for initial burst, ease in for gravity fall
        final burstProgress = Curves.easeOutBack.transform(math.min(1.0, progress * 1.4));
        final fadeProgress = progress > 0.75 ? (1.0 - progress) / 0.25 : 1.0;

        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central happy cartoon icon bouncing
              Transform.scale(
                scale: Curves.elasticOut.transform(math.min(1.0, progress * 1.2)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E599).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E599).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E599).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🥳',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),

              // Flying cartoon emoji particles
              ..._particles.map((p) {
                final currentDx = p.dx * burstProgress;
                final currentDy = (p.dy * burstProgress) + (progress * progress * 35.0); // slight gravity
                final currentScale = p.scale * (burstProgress < 0.2 ? burstProgress * 5 : 1.0);
                final currentRotation = p.rotation * burstProgress;

                return Transform.translate(
                  offset: Offset(currentDx, currentDy),
                  child: Transform.rotate(
                    angle: currentRotation,
                    child: Transform.scale(
                      scale: currentScale,
                      child: Opacity(
                        opacity: fadeProgress.clamp(0.0, 1.0),
                        child: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 26),
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

class _Particle {
  final String emoji;
  final double dx;
  final double dy;
  final double scale;
  final double rotation;

  _Particle({
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.scale,
    required this.rotation,
  });
}
