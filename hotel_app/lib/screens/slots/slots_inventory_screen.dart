import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TableSlotsScreen extends StatefulWidget {
  const TableSlotsScreen({super.key});

  @override
  State<TableSlotsScreen> createState() => _TableSlotsScreenState();
}

class _TableSlotsScreenState extends State<TableSlotsScreen> {
  int _selectedDateIndex = 0;
  String _shiftFilter = 'ALL';
  late List<DateTime> _dates;

  // Dedicated Slot Capacity Data
  late List<_SlotCapacityItem> _slots;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (i) => now.add(Duration(days: i)));

    _slots = [
      // Lunch
      _SlotCapacityItem(time: '12:00 PM', shift: 'LUNCH', totalTables: 8, bookedTables: 2, isOpen: true),
      _SlotCapacityItem(time: '12:30 PM', shift: 'LUNCH', totalTables: 10, bookedTables: 4, isOpen: true),
      _SlotCapacityItem(time: '01:00 PM', shift: 'LUNCH', totalTables: 12, bookedTables: 8, isOpen: true),
      _SlotCapacityItem(time: '01:30 PM', shift: 'LUNCH', totalTables: 12, bookedTables: 11, isOpen: true),
      _SlotCapacityItem(time: '02:00 PM', shift: 'LUNCH', totalTables: 8, bookedTables: 3, isOpen: true),
      _SlotCapacityItem(time: '02:30 PM', shift: 'LUNCH', totalTables: 8, bookedTables: 1, isOpen: false),

      // Dinner
      _SlotCapacityItem(time: '07:00 PM', shift: 'DINNER', totalTables: 10, bookedTables: 3, isOpen: true),
      _SlotCapacityItem(time: '07:30 PM', shift: 'DINNER', totalTables: 12, bookedTables: 6, isOpen: true),
      _SlotCapacityItem(time: '08:00 PM', shift: 'DINNER', totalTables: 14, bookedTables: 12, isOpen: true),
      _SlotCapacityItem(time: '08:30 PM', shift: 'DINNER', totalTables: 14, bookedTables: 13, isOpen: true),
      _SlotCapacityItem(time: '09:00 PM', shift: 'DINNER', totalTables: 12, bookedTables: 9, isOpen: true),
      _SlotCapacityItem(time: '09:30 PM', shift: 'DINNER', totalTables: 10, bookedTables: 4, isOpen: true),
      _SlotCapacityItem(time: '10:00 PM', shift: 'DINNER', totalTables: 8, bookedTables: 2, isOpen: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredSlots = _slots.where((s) {
      if (_shiftFilter == 'LUNCH') return s.shift == 'LUNCH';
      if (_shiftFilter == 'DINNER') return s.shift == 'DINNER';
      return true;
    }).toList();

    final totalTables = _slots.fold<int>(0, (sum, s) => sum + s.totalTables);
    final bookedTables = _slots.fold<int>(0, (sum, s) => sum + s.bookedTables);
    final openTables = totalTables - bookedTables;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table Slots & Capacity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Manage Table Inventory & Hourly Availability',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // 7-Day Date Selector
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _dates.length,
                itemBuilder: (context, idx) {
                  final date = _dates[idx];
                  final isSelected = _selectedDateIndex == idx;
                  final isToday = idx == 0;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDateIndex = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF222F49),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'TODAY' : DateFormat('E').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Capacity Overview Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF131D30), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F49)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      label: 'TOTAL CAPACITY',
                      value: '$totalTables Tables',
                      color: const Color(0xFF38BDF8),
                      icon: Icons.table_restaurant_rounded,
                    ),
                  ),
                  Container(width: 1, height: 38, color: const Color(0xFF1E283E)),
                  Expanded(
                    child: _buildMetric(
                      label: 'BOOKED TODAY',
                      value: '$bookedTables Tables',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  Container(width: 1, height: 38, color: const Color(0xFF1E283E)),
                  Expanded(
                    child: _buildMetric(
                      label: 'AVAILABLE FREE',
                      value: '$openTables Tables',
                      color: const Color(0xFF00E599),
                      icon: Icons.event_available_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shift Filter Chips
            Row(
              children: ['ALL', 'LUNCH', 'DINNER'].map((shift) {
                final isSel = _shiftFilter == shift;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _shiftFilter = shift);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF222F49),
                        ),
                      ),
                      child: Text(
                        shift == 'ALL' ? 'ALL SHIFTS' : (shift == 'LUNCH' ? 'LUNCH (12–3 PM)' : 'DINNER (7–11 PM)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                          color: isSel ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Slots List
            ...filteredSlots.map((slot) => _buildSlotCard(slot)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
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
    );
  }

  Widget _buildSlotCard(_SlotCapacityItem slot) {
    final occupancy = (slot.bookedTables / (slot.totalTables == 0 ? 1 : slot.totalTables));
    final available = slot.totalTables - slot.bookedTables;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: slot.isOpen ? const Color(0xFF101422) : const Color(0xFF0D101A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slot.isOpen ? const Color(0xFF1E283E) : const Color(0xFF1A2030),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F33),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF24324E)),
                    ),
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: slot.isOpen ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: slot.shift == 'LUNCH'
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFF818CF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slot.shift,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: slot.shift == 'LUNCH' ? const Color(0xFFFBBF24) : const Color(0xFFA5B4FC),
                      ),
                    ),
                  ),
                ],
              ),

              // Open / Close Switch
              Row(
                children: [
                  Text(
                    slot.isOpen ? 'OPEN' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: slot.isOpen ? const Color(0xFF00E599) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: slot.isOpen,
                    activeColor: const Color(0xFF00E599),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => slot.isOpen = val);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? '${slot.time} slot is now OPEN for diner bookings'
                                : '${slot.time} slot is now PAUSED (no bookings)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFF101420),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Utilization Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancy.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF182236),
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancy > 0.85
                    ? const Color(0xFFEF4444)
                    : (occupancy > 0.5 ? const Color(0xFFF59E0B) : const Color(0xFF00E599)),
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 10),

          // Table Adjust Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${slot.bookedTables} of ${slot.totalTables} Tables Booked ($available Available)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),

              // +/- Table capacity
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: slot.totalTables > slot.bookedTables
                        ? () {
                            HapticFeedback.lightImpact();
                            setState(() => slot.totalTables--);
                          }
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${slot.totalTables}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF38BDF8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => slot.totalTables++);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotCapacityItem {
  final String time;
  final String shift;
  int totalTables;
  final int bookedTables;
  bool isOpen;

  _SlotCapacityItem({
    required this.time,
    required this.shift,
    required this.totalTables,
    required this.bookedTables,
    required this.isOpen,
  });
}
