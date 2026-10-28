import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animated_stat_counter.dart';

class ShiftPulseBento extends StatefulWidget {
  final int todayCount;
  final int confirmedCount;
  final int pendingCount;
  final int expectedCovers;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ShiftPulseBento({
    super.key,
    required this.todayCount,
    required this.confirmedCount,
    required this.pendingCount,
    required this.expectedCovers,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<ShiftPulseBento> createState() => _ShiftPulseBentoState();
}

class _ShiftPulseBentoState extends State<ShiftPulseBento>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHIFT RESERVATION PULSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Tap any metric to filter live guest stream',
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 11, color: Color(0xFF64748B)),
                    SizedBox(width: 3),
                    Text(
                      'Interactive',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2x2 Connected Grid Matrix
          Row(
            children: [
              Expanded(
                child: _buildQuadrant(
                  title: 'TOTAL BOOKINGS',
                  value: widget.todayCount,
                  subtitle: '+18% Today',
                  icon: Icons.calendar_month_rounded,
                  accentColor: const Color(0xFFD97706), // warm amber
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  filterKey: 'ALL',
                  isSelected: widget.selectedFilter == 'ALL',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuadrant(
                  title: 'CONFIRMED TABLES',
                  value: widget.confirmedCount,
                  subtitle: '85% Occupancy',
                  icon: Icons.check_circle_rounded,
                  accentColor: const Color(0xFF059669), // emerald
                  bgColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                  filterKey: 'CONFIRMED',
                  isSelected: widget.selectedFilter == 'CONFIRMED',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return _buildQuadrant(
                      title: 'ACTION REQUIRED',
                      value: widget.pendingCount,
                      subtitle: widget.pendingCount > 0 ? 'Awaiting Host' : 'All Clear',
                      icon: Icons.notification_important_rounded,
                      accentColor: const Color(0xFFEA580C), // orange
                      bgColor: const Color(0xFFFFF7ED),
                      borderColor: const Color(0xFFFED7AA),
                      filterKey: 'PENDING',
                      isSelected: widget.selectedFilter == 'PENDING',
                      isPulsing: widget.pendingCount > 0,
                      pulseOpacity: _glowAnimation.value,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuadrant(
                  title: 'EXPECTED COVERS',
                  value: widget.expectedCovers,
                  subtitle: 'Dinner Peak',
                  icon: Icons.groups_rounded,
                  accentColor: const Color(0xFF4F46E5), // indigo
                  bgColor: const Color(0xFFEEF2FF),
                  borderColor: const Color(0xFFC7D2FE),
                  filterKey: 'ALL',
                  isSelected: false,
                  valueSuffix: ' Guests',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrant({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required String filterKey,
    required bool isSelected,
    bool isPulsing = false,
    double pulseOpacity = 0.0,
    String valueSuffix = '',
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onFilterChanged(filterKey);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.14) : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isPulsing
                      ? accentColor.withValues(alpha: pulseOpacity)
                      : borderColor),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title & icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isSelected ? accentColor : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(icon, size: 13, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Value row with animated counter
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedStatCounter(
                    targetValue: value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (valueSuffix.isNotEmpty)
                    Text(
                      valueSuffix,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Subtitle tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
