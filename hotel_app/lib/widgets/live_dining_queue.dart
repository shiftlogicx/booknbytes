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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Live Operational Flow
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
                        color: Color(0xFF00E599), // CRED Neon Emerald
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
                  const SizedBox(width: 10),
                  const Text(
                    'LIVE DINING CAPACITY & FLOW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E599).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E599).withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'PEAK SERVICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E599),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Real-time Capacity Meter Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DINING ROOM UTILIZATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '82% (34 of 42 Covers Active)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E599),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E283E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.82,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E599), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E599).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Operational Quick Stats Strip (3 Pills)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timer_outlined,
                  label: 'AVG DWELL',
                  value: '42 mins',
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.table_bar_rounded,
                  label: 'FREE TABLES',
                  value: '4 Tables',
                  color: const Color(0xFF00E599),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.schedule_rounded,
                  label: 'NEXT GUEST',
                  value: 'In 12m',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFF1E273A)),
          const SizedBox(height: 16),

          // Upcoming Rush Timeline
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPCOMING RUSH TIMELINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                'Tonight Service',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),

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
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF202738)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF182234)
            : const Color(0xFF141824),
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222B3D)),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: tagColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 11,
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
