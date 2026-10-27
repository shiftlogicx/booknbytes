import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiveDiningQueueTracker extends StatefulWidget {
  const LiveDiningQueueTracker({super.key});

  @override
  State<LiveDiningQueueTracker> createState() => _LiveDiningQueueTrackerState();
}

class _LiveDiningQueueTrackerState extends State<LiveDiningQueueTracker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isTimelineExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101422),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E283E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Distinct Visual Identity for Dining Room & Capacity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E599),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E599),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DINING ROOM & TABLE CAPACITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Physical floor occupancy & table turnover',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E599).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E599).withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  '82% FULL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E599),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Visual Gauge & Live Turnover Metrics in a Row
          Row(
            children: [
              // Visual Animated Radial Gauge (Left)
              const RadialCapacityGauge(
                percentage: 0.82,
                activeCovers: 34,
                totalCovers: 42,
              ),

              const SizedBox(width: 14),

              // Live Turnover Metrics (Right)
              Expanded(
                child: Column(
                  children: [
                    _buildMetricTile(
                      icon: Icons.timer_outlined,
                      label: 'AVG DWELL TIME',
                      value: '42 mins',
                      accentColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 6),
                    _buildMetricTile(
                      icon: Icons.table_bar_rounded,
                      label: 'OPEN TABLES',
                      value: '4 Tables (8 Covers)',
                      accentColor: const Color(0xFF00E599),
                    ),
                    const SizedBox(height: 6),
                    _buildMetricTile(
                      icon: Icons.schedule_rounded,
                      label: 'NEXT GUEST IN',
                      value: '12m · T-04 (Aditya)',
                      accentColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Collapsible Shift Rush Schedule Button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isTimelineExpanded = !_isTimelineExpanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141926),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2638)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 13,
                        color: Color(0xFF818CF8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTimelineExpanded
                            ? 'Hide Service Rush Schedule'
                            : 'View Service Rush Schedule (Tonight)',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isTimelineExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF818CF8),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Rush Timeline
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isTimelineExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildTimelineSlot(
                        time: '08:00 PM',
                        tag: 'SEATING NOW',
                        tagColor: const Color(0xFF00E599),
                        details: '6 Tables · 18 Guests (Walk-in & Reserved)',
                        isCurrent: true,
                      ),
                      _buildTimelineSlot(
                        time: '08:30 PM',
                        tag: 'NEXT ARRIVAL',
                        tagColor: const Color(0xFFF59E0B),
                        details: 'Aditya & Ananya Roy · Table T-04 · 4 Guests',
                        isCurrent: false,
                      ),
                      _buildTimelineSlot(
                        time: '09:00 PM',
                        tag: 'PEAK DINNER',
                        tagColor: const Color(0xFF6366F1),
                        details: '8 Tables Booked · 24 Guests Confirmed',
                        isCurrent: false,
                      ),
                      _buildTimelineSlot(
                        time: '09:45 PM',
                        tag: 'LATE NIGHT',
                        tagColor: const Color(0xFF64748B),
                        details: '3 Tables Booked · 25% Off Active',
                        isCurrent: false,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlot({
    required String time,
    required String tag,
    required Color tagColor,
    required String details,
    required bool isCurrent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF182234) : const Color(0xFF141824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? tagColor.withValues(alpha: 0.45)
              : const Color(0xFF1E2536),
          width: isCurrent ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF222B3D)),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: tagColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadialCapacityGauge extends StatefulWidget {
  final double percentage;
  final int activeCovers;
  final int totalCovers;

  const RadialCapacityGauge({
    super.key,
    required this.percentage,
    required this.activeCovers,
    required this.totalCovers,
  });

  @override
  State<RadialCapacityGauge> createState() => _RadialCapacityGaugeState();
}

class _RadialCapacityGaugeState extends State<RadialCapacityGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(RadialCapacityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _anim = Tween<double>(begin: _anim.value, end: widget.percentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(118, 118),
          painter: _RadialGaugePainter(percentage: _anim.value),
          child: SizedBox(
            width: 118,
            height: 118,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_anim.value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${widget.activeCovers}/${widget.totalCovers} SEATS',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E599),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double percentage;

  _RadialGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const startAngle = 135 * (math.pi / 180);
    const totalSweep = 270 * (math.pi / 180);

    final trackPaint = Paint()
      ..color = const Color(0xFF1E283E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    const gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalSweep,
      colors: const [
        Color(0xFF00E599),
        Color(0xFF38BDF8),
        Color(0xFF818CF8),
      ],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E599).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final currentSweep = totalSweep * percentage.clamp(0.0, 1.0);

    if (currentSweep > 0) {
      canvas.drawArc(rect, startAngle, currentSweep, false, glowPaint);
      canvas.drawArc(rect, startAngle, currentSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(_RadialGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
