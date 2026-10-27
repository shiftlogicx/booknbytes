import 'package:flutter/material.dart';

class PremiumBrandLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const PremiumBrandLogo({
    super.key,
    this.size = 80,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E2638),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.25),
            blurRadius: size * 0.35,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: size * 0.035,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner subtle metallic ring
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFDE047).withOpacity(0.4),
                width: 1.2,
              ),
            ),
          ),
          // Center Cloche & Cutlery
          Icon(
            Icons.dinner_dining_rounded,
            size: size * 0.48,
            color: const Color(0xFFFBBF24),
          ),
          if (showBadge)
            Positioned(
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PARTNER',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
