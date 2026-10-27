import 'package:flutter/material.dart';
import 'animated_stat_counter.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final numValue = num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    final isCurrency = value.startsWith('₹') || value.startsWith('\$');
    final suffix = value.endsWith('%') ? '%' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF222B3D),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),

          // Animated Numeric Value or Plain Text
          if (numValue != null)
            AnimatedStatCounter(
              targetValue: numValue,
              prefix: isCurrency ? '₹' : '',
              suffix: suffix,
              isCurrency: isCurrency,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),

          // Trend and Subtitle
          if (trend != null || subtitle != null) ...[
            Row(
              children: [
                if (trend != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trend!.startsWith('+') ? const Color(0xFF00E599) : const Color(0xFF94A3B8)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: trend!.startsWith('+') ? const Color(0xFF00E599) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
