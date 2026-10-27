import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TableStatus {
  available,
  seated,
  reserved,
  billing,
}

class DiningTableItem {
  final String id;
  final String name; // e.g. "T-01"
  final String section; // "Main Dining", "Window Bay", "VIP Lounge", "Patio"
  final int capacity;
  TableStatus status;
  String? guestName;
  String? timeSlot;

  DiningTableItem({
    required this.id,
    required this.name,
    required this.section,
    required this.capacity,
    required this.status,
    this.guestName,
    this.timeSlot,
  });

  Color get statusColor {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF00E599); // CRED Neon Emerald
      case TableStatus.seated:
        return const Color(0xFF38BDF8); // Electric Sky
      case TableStatus.reserved:
        return const Color(0xFFF59E0B); // Radiant Amber
      case TableStatus.billing:
        return const Color(0xFFA855F7); // Neon Purple
    }
  }

  String get statusLabel {
    switch (status) {
      case TableStatus.available:
        return 'AVAILABLE';
      case TableStatus.seated:
        return 'OCCUPIED';
      case TableStatus.reserved:
        return 'RESERVED';
      case TableStatus.billing:
        return 'BILLING';
    }
  }
}

class InteractiveFloorMap extends StatefulWidget {
  const InteractiveFloorMap({super.key});

  @override
  State<InteractiveFloorMap> createState() => _InteractiveFloorMapState();
}

class _InteractiveFloorMapState extends State<InteractiveFloorMap> {
  String _selectedSection = 'ALL';

  late List<DiningTableItem> _tables;

  @override
  void initState() {
    super.initState();
    _tables = [
      DiningTableItem(
        id: 'tb_01',
        name: 'T-01',
        section: 'Main Dining',
        capacity: 4,
        status: TableStatus.seated,
        guestName: 'Karan Mehra',
        timeSlot: '08:00 PM',
      ),
      DiningTableItem(
        id: 'tb_02',
        name: 'T-02',
        section: 'Window Bay',
        capacity: 2,
        status: TableStatus.available,
      ),
      DiningTableItem(
        id: 'tb_03',
        name: 'T-03',
        section: 'VIP Lounge',
        capacity: 6,
        status: TableStatus.reserved,
        guestName: 'Dr. Sameer Kapoor',
        timeSlot: '08:45 PM',
      ),
      DiningTableItem(
        id: 'tb_04',
        name: 'T-04',
        section: 'Main Dining',
        capacity: 4,
        status: TableStatus.reserved,
        guestName: 'Aditya & Ananya Roy',
        timeSlot: '08:30 PM',
      ),
      DiningTableItem(
        id: 'tb_05',
        name: 'T-05',
        section: 'Patio',
        capacity: 4,
        status: TableStatus.available,
      ),
      DiningTableItem(
        id: 'tb_06',
        name: 'T-06',
        section: 'Patio',
        capacity: 8,
        status: TableStatus.seated,
        guestName: 'TechCorp Dinner (8)',
        timeSlot: '07:30 PM',
      ),
      DiningTableItem(
        id: 'tb_07',
        name: 'T-07',
        section: 'Main Dining',
        capacity: 2,
        status: TableStatus.billing,
        guestName: 'Priya Sen',
        timeSlot: '07:15 PM',
      ),
      DiningTableItem(
        id: 'tb_08',
        name: 'T-08',
        section: 'VIP Lounge',
        capacity: 10,
        status: TableStatus.available,
      ),
    ];
  }

  void _showTableActions(DiningTableItem table) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF101420),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF232B3E), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: table.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: table.statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: table.statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${table.capacity} Seater · ${table.section}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            table.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: table.statusColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              if (table.guestName != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171D2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF26324D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              table.guestName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Reserved Slot: ${table.timeSlot ?? "Live"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              const Text(
                'QUICK TABLE STATUS UPDATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Mark Available',
                      color: const Color(0xFF00E599),
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          table.status = TableStatus.available;
                          table.guestName = null;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Seat Guests',
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          table.status = TableStatus.seated;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Bill Print',
                      color: const Color(0xFFA855F7),
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          table.status = TableStatus.billing;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tables.where((t) {
      if (_selectedSection == 'ALL') return true;
      return t.section == _selectedSection;
    }).toList();

    final availableCount = _tables.where((t) => t.status == TableStatus.available).length;
    final seatedCount = _tables.where((t) => t.status == TableStatus.seated).length;
    final reservedCount = _tables.where((t) => t.status == TableStatus.reserved).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF20273A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Live Pulse Radar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
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
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE DINING FLOOR PLAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$availableCount / ${_tables.length} Free',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00E599),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Legend Indicators Strip
          Row(
            children: [
              _buildLegendDot(const Color(0xFF00E599), 'Available ($availableCount)'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF38BDF8), 'Occupied ($seatedCount)'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFFF59E0B), 'Reserved ($reservedCount)'),
            ],
          ),

          const SizedBox(height: 16),

          // Section Selector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['ALL', 'Main Dining', 'Window Bay', 'VIP Lounge', 'Patio'].map((sec) {
                final isSelected = _selectedSection == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSection = sec);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF26324D) : const Color(0xFF151A2A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF20273A),
                        ),
                      ),
                      child: Text(
                        sec,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Tables Grid (2x4)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, idx) {
              final table = filtered[idx];
              return _buildTableCard(table);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTableCard(DiningTableItem table) {
    return InkWell(
      onTap: () => _showTableActions(table),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: table.statusColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: table.statusColor.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: table.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    table.statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: table.statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (table.guestName != null) ...[
                  Text(
                    table.guestName!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    table.timeSlot ?? '${table.capacity} Guests',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ] else ...[
                  Text(
                    '${table.capacity} Seater Table',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    table.section,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
