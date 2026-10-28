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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Embossed Restaurant Crest
          CustomPaint(
            size: Size(size, size),
            painter: _RestaurantCrestPainter(),
          ),

          // Badge Pill at bottom
          if (showBadge)
            Positioned(
              bottom: size * 0.04,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.08,
                  vertical: size * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: size * 0.1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'RESTAURANT',
                  style: TextStyle(
                    fontSize: (size * 0.085).clamp(8.0, 14.0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RestaurantCrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Luxury Outer Rounded Shield / Crest
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.04, w * 0.92, h * 0.92),
      Radius.circular(w * 0.28),
    );

    // Background Gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1E283E), Color(0xFF0F1422)],
        center: Alignment(0.0, -0.2),
        radius: 0.85,
      ).createShader(rrect.outerRect);

    canvas.drawRRect(rrect, bgPaint);

    // Glowing Gold & Emerald Border
    final borderPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFF59E0B),
          Color(0xFF00E599),
          Color(0xFFFBBF24),
          Color(0xFFF59E0B),
        ],
      ).createShader(rrect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.035).clamp(2.0, 5.0);

    canvas.drawRRect(rrect, borderPaint);

    // Soft Shadow
    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.06).clamp(3.0, 8.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, glowPaint);

    // 2. Fine Inner Filigree Ring
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.09, h * 0.09, w * 0.82, h * 0.82),
      Radius.circular(w * 0.24),
    );
    final innerLinePaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(innerRRect, innerLinePaint);

    // 3. Central Dining Cloche (Serving Dome)
    final clocheWidth = w * 0.44;
    final clocheHeight = h * 0.24;
    final clocheBottomY = h * 0.54;
    final clocheTopY = clocheBottomY - clocheHeight;

    // Dome Path
    final domePath = Path();
    domePath.moveTo(center.dx - clocheWidth / 2, clocheBottomY);
    domePath.cubicTo(
      center.dx - clocheWidth / 2,
      clocheTopY + clocheHeight * 0.1,
      center.dx + clocheWidth / 2,
      clocheTopY + clocheHeight * 0.1,
      center.dx + clocheWidth / 2,
      clocheBottomY,
    );
    domePath.close();

    final domePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(center.dx - clocheWidth / 2, clocheTopY, clocheWidth, clocheHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(domePath, domePaint);

    // Dome Top Ring / Handle
    final handlePaint = Paint()
      ..color = const Color(0xFFFFFBEB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, clocheTopY - (w * 0.025)), w * 0.038, handlePaint);

    final handleHolePaint = Paint()
      ..color = const Color(0xFF1E283E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, clocheTopY - (w * 0.025)), w * 0.016, handleHolePaint);

    // Serving Platter Base Rim
    final platterRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, clocheBottomY + (h * 0.02)),
        width: clocheWidth * 1.25,
        height: h * 0.035,
      ),
      Radius.circular(w * 0.02),
    );
    final platterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFBBF24), Color(0xFFF59E0B)],
      ).createShader(platterRect.outerRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(platterRect, platterPaint);

    // 4. Crossed Fork & Knife Beneath Platter
    final cutleryY = clocheBottomY + (h * 0.08);
    _drawCrossedCutlery(canvas, center.dx, cutleryY, w * 0.32, h * 0.12);

    // 5. Delicate Rising Aroma Wisps (Steam)
    final steamPaint = Paint()
      ..color = const Color(0xFF00E599).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final steam1 = Path();
    steam1.moveTo(center.dx - w * 0.07, clocheTopY - h * 0.06);
    steam1.quadraticBezierTo(center.dx - w * 0.09, clocheTopY - h * 0.10, center.dx - w * 0.06, clocheTopY - h * 0.14);
    canvas.drawPath(steam1, steamPaint);

    final steam2 = Path();
    steam2.moveTo(center.dx + w * 0.07, clocheTopY - h * 0.06);
    steam2.quadraticBezierTo(center.dx + w * 0.05, clocheTopY - h * 0.10, center.dx + w * 0.08, clocheTopY - h * 0.14);
    canvas.drawPath(steam2, steamPaint);
  }

  void _drawCrossedCutlery(Canvas canvas, double cx, double cy, double width, double height) {
    final cutleryPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Fork (diagonal left-to-right)
    canvas.drawLine(
      Offset(cx - width / 2, cy - height / 2),
      Offset(cx + width / 2, cy + height / 2),
      cutleryPaint,
    );

    // Knife (diagonal right-to-left)
    canvas.drawLine(
      Offset(cx + width / 2, cy - height / 2),
      Offset(cx - width / 2, cy + height / 2),
      cutleryPaint,
    );

    // Center pivot jewel
    final jewelPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(cx, cy), 2.5, jewelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
