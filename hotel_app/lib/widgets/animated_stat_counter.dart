import 'package:flutter/material.dart';

class AnimatedStatCounter extends StatelessWidget {
  final num targetValue;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final Duration duration;
  final bool isCurrency;

  const AnimatedStatCounter({
    super.key,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    required this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        String display;
        if (isCurrency) {
          display = '$prefix${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}$suffix';
        } else if (targetValue is int) {
          display = '$prefix${value.toInt()}$suffix';
        } else {
          display = '$prefix${value.toStringAsFixed(1)}$suffix';
        }

        return Text(
          display,
          style: style,
        );
      },
    );
  }
}
