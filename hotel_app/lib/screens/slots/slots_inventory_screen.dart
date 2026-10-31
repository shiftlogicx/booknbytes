import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/slot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/slots_provider.dart';

class TableSlotsScreen extends StatefulWidget {
  const TableSlotsScreen({super.key});

  @override
  State<TableSlotsScreen> createState() => _TableSlotsScreenState();
}

class _TableSlotsScreenState extends State<TableSlotsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final slots = Provider.of<SlotsProvider>(context, listen: false);
      if (auth.currentRestaurantId.isNotEmpty) {
        slots.loadSlots(auth.currentRestaurantId);
      }
    });
  }

  void _showPublishSlotSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    TimeOfDay selectedStartTime = const TimeOfDay(hour: 13, minute: 0);
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 15, minute: 0);
    int capacity = 30;
    double discount = 20.0;
    String shift = 'LUNCH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final selDate = slotsProvider.selectedDate;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Publish Table Slots',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    Text(
                      'Date: ${DateFormat('EEE, dd MMM yyyy').format(selDate)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),

                    // Shift Selector
                    const Text('OPERATING SHIFT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('LUNCH (11 AM - 4 PM)')),
                            selected: shift == 'LUNCH',
                            selectedColor: const Color(0xFFECFDF5),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: shift == 'LUNCH' ? const Color(0xFF059669) : const Color(0xFF475569),
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  shift = 'LUNCH';
                                  selectedStartTime = const TimeOfDay(hour: 12, minute: 30);
                                  selectedEndTime = const TimeOfDay(hour: 14, minute: 30);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('DINNER (7 PM - 11 PM)')),
                            selected: shift == 'DINNER',
                            selectedColor: const Color(0xFFEEF2FF),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: shift == 'DINNER' ? const Color(0xFF2563EB) : const Color(0xFF475569),
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  shift = 'DINNER';
                                  selectedStartTime = const TimeOfDay(hour: 19, minute: 30);
                                  selectedEndTime = const TimeOfDay(hour: 21, minute: 30);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Time Range Selector
                    const Text('TIME WINDOW',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: ctx, initialTime: selectedStartTime);
                              if (picked != null) setModalState(() => selectedStartTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('START TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  Text(selectedStartTime.format(ctx),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: ctx, initialTime: selectedEndTime);
                              if (picked != null) setModalState(() => selectedEndTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('END TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  Text(selectedEndTime.format(ctx),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Table Capacity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TABLE CAPACITY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                            SizedBox(height: 2),
                            Text('Max covers allowed in this slot', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF94A3B8), size: 24),
                              onPressed: capacity > 5 ? () => setModalState(() => capacity -= 5) : null,
                            ),
                            Text('$capacity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669), size: 24),
                              onPressed: capacity < 150 ? () => setModalState(() => capacity += 5) : null,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Discount Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DYNAMIC DISCOUNT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                            SizedBox(height: 2),
                            Text('Incentive to attract off-peak footfall', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text('${discount.toInt()}% OFF',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD97706), fontSize: 13)),
                        ),
                      ],
                    ),
                    Slider(
                      value: discount,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      activeColor: const Color(0xFF059669),
                      inactiveColor: const Color(0xFFE2E8F0),
                      label: '${discount.toInt()}% OFF',
                      onChanged: (val) => setModalState(() => discount = val),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final startDt = DateTime(selDate.year, selDate.month, selDate.day, selectedStartTime.hour, selectedStartTime.minute);
                          final endDt = DateTime(selDate.year, selDate.month, selDate.day, selectedEndTime.hour, selectedEndTime.minute);

                          final success = await slotsProvider.publishSlot(
                            restaurantId: auth.currentRestaurantId,
                            startDatetime: startDt,
                            endDatetime: endDt,
                            discountPercentage: discount,
                            capacity: capacity,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Table slot successfully published!'
                                      : 'Failed to publish slot: ${slotsProvider.errorMessage}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: const Text('Publish the Slots', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotsProvider = Provider.of<SlotsProvider>(context);
    final filtered = slotsProvider.filteredSlots;
    final totalCapacity = filtered.fold<int>(0, (sum, s) => sum + s.capacity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table Slots & Capacity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Live Floor Inventory & Shift Management',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669)),
            tooltip: 'Publish New Slot',
            onPressed: () => _showPublishSlotSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            // 7-Day Date Selector
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: slotsProvider.dates.length,
                itemBuilder: (context, idx) {
                  final date = slotsProvider.dates[idx];
                  final isSelected = slotsProvider.selectedDateIndex == idx;
                  final isToday = idx == 0;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      slotsProvider.setSelectedDateIndex(idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : const [
                                BoxShadow(
                                  color: Color(0x060F172A),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : (isToday ? const Color(0xFF059669) : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Capacity Overview Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCol(
                      label: 'TOTAL SLOTS',
                      value: '${filtered.length}',
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: _buildMetricCol(
                      label: 'TOTAL COVERS',
                      value: '$totalCapacity',
                      color: const Color(0xFF059669),
                    ),
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: _buildMetricCol(
                      label: 'ACTIVE SHIFTS',
                      value: '2 (L/D)',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shift Filter Pills
            Row(
              children: [
                _buildShiftChip('ALL', 'All Shifts (${slotsProvider.slots.length})', slotsProvider),
                const SizedBox(width: 8),
                _buildShiftChip('LUNCH', 'Lunch', slotsProvider),
                const SizedBox(width: 8),
                _buildShiftChip('DINNER', 'Dinner', slotsProvider),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showPublishSlotSheet(context),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF059669)),
                  label: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF059669))),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (slotsProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text('No slots scheduled for this shift/date',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showPublishSlotSheet(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Publish First Slot', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((slot) => _buildLiveSlotCard(slot, slotsProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftChip(String key, String label, SlotsProvider provider) {
    final isSelected = provider.shiftFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        provider.setShiftFilter(key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSlotCard(DailySlotModel slot, SlotsProvider provider) {
    final isLunch = slot.shift == 'LUNCH';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLunch ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slot.shift,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isLunch ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                slot.timeFormatted,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (slot.discountPercentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '${slot.discountPercentage.toInt()}% OFF',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await provider.deleteSlot(slot.slotId);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capacity: ${slot.capacity} covers registered',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: slot.capacity > 5
                        ? () => provider.updateSlot(slot.slotId, capacity: slot.capacity - 5)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${slot.capacity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF059669)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => provider.updateSlot(slot.slotId, capacity: slot.capacity + 5),
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
