import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/slot_discount_model.dart';

class SlotManagementScreen extends StatefulWidget {
  final bool isTab;

  const SlotManagementScreen({super.key, this.isTab = false});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  int _selectedDateIndex = 0;
  String _selectedShiftFilter = 'ALL'; // 'ALL', 'LUNCH', 'DINNER'
  bool _isSaving = false;

  late List<DateTime> _dates;
  late List<SlotDiscountModel> _slots;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (i) => now.add(Duration(days: i)));

    // Initial mock slot data with differential discounts
    _slots = [
      // Lunch Shift
      SlotDiscountModel(
        id: 'slot_1200',
        time: '12:00 PM',
        shift: SlotShift.lunch,
        capacityTables: 8,
        bookedTables: 2,
        discountPercentage: 20,
        tag: 'Early Bird',
      ),
      SlotDiscountModel(
        id: 'slot_1230',
        time: '12:30 PM',
        shift: SlotShift.lunch,
        capacityTables: 10,
        bookedTables: 4,
        discountPercentage: 15,
      ),
      SlotDiscountModel(
        id: 'slot_1300',
        time: '01:00 PM',
        shift: SlotShift.lunch,
        capacityTables: 12,
        bookedTables: 7,
        discountPercentage: 10,
      ),
      SlotDiscountModel(
        id: 'slot_1330',
        time: '01:30 PM',
        shift: SlotShift.lunch,
        capacityTables: 12,
        bookedTables: 9,
        discountPercentage: 0,
        tag: 'Peak Lunch',
      ),
      SlotDiscountModel(
        id: 'slot_1400',
        time: '02:00 PM',
        shift: SlotShift.lunch,
        capacityTables: 8,
        bookedTables: 3,
        discountPercentage: 25,
        tag: 'Happy Hour',
      ),

      // Dinner Shift
      SlotDiscountModel(
        id: 'slot_1900',
        time: '07:00 PM',
        shift: SlotShift.dinner,
        capacityTables: 10,
        bookedTables: 3,
        discountPercentage: 20,
        tag: 'Early Dinner',
      ),
      SlotDiscountModel(
        id: 'slot_1930',
        time: '07:30 PM',
        shift: SlotShift.dinner,
        capacityTables: 12,
        bookedTables: 6,
        discountPercentage: 15,
      ),
      SlotDiscountModel(
        id: 'slot_2000',
        time: '08:00 PM',
        shift: SlotShift.dinner,
        capacityTables: 14,
        bookedTables: 11,
        discountPercentage: 0,
        tag: 'Prime Time',
      ),
      SlotDiscountModel(
        id: 'slot_2030',
        time: '08:30 PM',
        shift: SlotShift.dinner,
        capacityTables: 14,
        bookedTables: 13,
        discountPercentage: 0,
        tag: 'Prime Time',
      ),
      SlotDiscountModel(
        id: 'slot_2100',
        time: '09:00 PM',
        shift: SlotShift.dinner,
        capacityTables: 12,
        bookedTables: 10,
        discountPercentage: 10,
      ),
      SlotDiscountModel(
        id: 'slot_2130',
        time: '09:30 PM',
        shift: SlotShift.dinner,
        capacityTables: 10,
        bookedTables: 4,
        discountPercentage: 20,
      ),
      SlotDiscountModel(
        id: 'slot_2200',
        time: '10:00 PM',
        shift: SlotShift.dinner,
        capacityTables: 8,
        bookedTables: 2,
        discountPercentage: 30,
        tag: 'Late Night Deal',
      ),
    ];
  }

  void _applyQuickPreset(String type) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (type == 'early_bird') {
        for (var s in _slots) {
          if (s.time == '12:00 PM' || s.time == '07:00 PM') {
            s.discountPercentage = 25;
            s.tag = 'Early Bird';
          }
        }
      } else if (type == 'happy_hour') {
        for (var s in _slots) {
          if (s.time == '02:00 PM' || s.time == '10:00 PM') {
            s.discountPercentage = 30;
            s.tag = 'Happy Hour';
          }
        }
      } else if (type == 'prime_zero') {
        for (var s in _slots) {
          if (s.time == '08:00 PM' || s.time == '08:30 PM' || s.time == '01:30 PM') {
            s.discountPercentage = 0;
            s.tag = 'Prime Time';
          }
        }
      } else if (type == 'open_all') {
        for (var s in _slots) {
          s.isAvailable = true;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Preset Applied: ${type.replaceAll('_', ' ').toUpperCase()} ✨'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _publishChanges() async {
    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _isSaving = false);

    final discountedCount = _slots.where((s) => s.discountPercentage > 0 && s.isAvailable).length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🏷️ 🚀 Published Live! $discountedCount discounted slots available to diners! ✨',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSlots = _slots.where((s) {
      if (_selectedShiftFilter == 'LUNCH') return s.shift == SlotShift.lunch;
      if (_selectedShiftFilter == 'DINNER') return s.shift == SlotShift.dinner;
      return true;
    }).toList();

    final activeDiscountsCount = _slots.where((s) => s.discountPercentage > 0 && s.isAvailable).length;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF101726),
              elevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slots & Dynamic Discounts',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Set differential table discounts per hour',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
      body: Column(
        children: [
          // Date Selector Strip
          _buildDateSelector(),

          // Quick Presets Bar
          _buildQuickPresetsBar(),

          // Shift Filter Chips
          _buildShiftFilterBar(),

          // Slot Cards List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, widget.isTab ? 160 : 90),
              itemCount: filteredSlots.length,
              itemBuilder: (context, idx) {
                return _buildSlotCard(filteredSlots[idx]);
              },
            ),
          ),
        ],
      ),

      // Bottom Sticky Publish Bar
      bottomSheet: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: widget.isTab ? 10 : 14,
        ),
        margin: EdgeInsets.only(bottom: widget.isTab ? 78 : 0),
        decoration: BoxDecoration(
          color: const Color(0xFF101726),
          border: const Border(
            top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$activeDiscountsCount Slots Discounted',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Live sync with diners',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _publishChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isSaving ? 'Publishing...' : 'Publish Slots',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Date Selector Strip
  Widget _buildDateSelector() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF101726),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, idx) {
          final date = _dates[idx];
          final isSelected = idx == _selectedDateIndex;
          final isToday = idx == 0;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDateIndex = idx);
            },
            child: Container(
              width: 68,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF172033),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF222F49),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Quick Presets Bar
  Widget _buildQuickPresetsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0C121F),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              const Text(
                'QUICK DISCOUNT PRESETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPresetChip(
                  '⚡ Early Bird (25%)',
                  () => _applyQuickPreset('early_bird'),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  '🍹 Happy Hour (30%)',
                  () => _applyQuickPreset('happy_hour'),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  '👑 Prime Time (0%)',
                  () => _applyQuickPreset('prime_zero'),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  '🔓 Open All Slots',
                  () => _applyQuickPreset('open_all'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  /// Shift Filter Bar
  Widget _buildShiftFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All Slots (${_slots.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('LUNCH', 'Lunch (5)'),
          const SizedBox(width: 8),
          _buildFilterChip('DINNER', 'Dinner (7)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedShiftFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedShiftFilter = filterKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.2) : const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF222F49),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  /// Interactive Slot Card
  Widget _buildSlotCard(SlotDiscountModel slot) {
    final isDinner = slot.shift == SlotShift.dinner;
    final hasDiscount = slot.discountPercentage > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slot.isAvailable ? const Color(0xFF131B2E) : const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDiscount && slot.isAvailable
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : const Color(0xFF222F49),
          width: hasDiscount && slot.isAvailable ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Time, Shift Pill, Tag, and Open/Closed Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDinner
                          ? const Color(0xFF6366F1).withOpacity(0.18)
                          : const Color(0xFFF59E0B).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDinner ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                      size: 16,
                      color: isDinner ? const Color(0xFF818CF8) : const Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    slot.time,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: slot.isAvailable ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  if (slot.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot.tag!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Availability Switch
              Row(
                children: [
                  Text(
                    slot.isAvailable ? 'OPEN' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: slot.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: slot.isAvailable,
                      activeColor: const Color(0xFF10B981),
                      activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                      inactiveThumbColor: const Color(0xFF64748B),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => slot.isAvailable = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (slot.isAvailable) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFF1E2638)),
            const SizedBox(height: 14),

            // Table Capacity Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TABLE CAPACITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.availableTables} tables left · ${slot.bookedTables} booked',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStepperBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (slot.capacityTables > slot.bookedTables) {
                          HapticFeedback.selectionClick();
                          setState(() => slot.capacityTables--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${slot.capacityTables}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildStepperBtn(
                      icon: Icons.add,
                      onTap: () {
                        if (slot.capacityTables < 30) {
                          HapticFeedback.selectionClick();
                          setState(() => slot.capacityTables++);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Dynamic Discount Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SLOT DISCOUNT FOR DINERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        '🔥 ${slot.discountPercentage}% OFF Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [0, 10, 15, 20, 25, 30, 40].map((pct) {
                      final isSelected = slot.discountPercentage == pct;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => slot.discountPercentage = pct);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (pct > 0 ? const Color(0xFFF59E0B) : const Color(0xFF334155))
                                  : const Color(0xFF172033),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? (pct > 0 ? const Color(0xFFF59E0B) : const Color(0xFF475569))
                                    : const Color(0xFF222F49),
                              ),
                            ),
                            child: Text(
                              pct == 0 ? 'No Disc' : '$pct% OFF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? (pct > 0 ? Colors.black : Colors.white)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
