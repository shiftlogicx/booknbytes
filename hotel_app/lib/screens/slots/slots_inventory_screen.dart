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
  bool _isSavingDynamic = false;
  double _minDiscount = 10.0;
  double _maxDiscount = 30.0;
  bool _dynamicEnabled = true;
  int _sampleRolledDiscount = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final slots = Provider.of<SlotsProvider>(context, listen: false);
      if (auth.currentRestaurantId.isNotEmpty && slots.slots.isEmpty && !slots.isLoading) {
        slots.loadSlots(auth.currentRestaurantId);
      }
      final profile = auth.profile;
      setState(() {
        _dynamicEnabled = profile.dynamicDiscountEnabled;
        _minDiscount = profile.minDiscount.toDouble().clamp(5.0, 30.0);
        _maxDiscount = profile.maxDiscount.toDouble().clamp(15.0, 60.0);
        if (_maxDiscount < _minDiscount) _maxDiscount = _minDiscount;
        _rollSampleDiscount();
      });
    });
  }

  void _rollSampleDiscount() {
    final min = _minDiscount.round();
    final max = _maxDiscount.round();
    if (min >= max) {
      _sampleRolledDiscount = min;
    } else {
      final delta = max - min;
      final randomOffset = (DateTime.now().microsecondsSinceEpoch % (delta + 1));
      _sampleRolledDiscount = (min + randomOffset).clamp(min, max);
    }
  }

  Future<void> _saveDynamicDiscount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isSavingDynamic = true);
    final success = await auth.updateDynamicDiscount(
      enabled: _dynamicEnabled,
      minDiscount: _minDiscount.round(),
      maxDiscount: _maxDiscount.round(),
    );
    if (mounted) {
      setState(() => _isSavingDynamic = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Dynamic slot discount (${_minDiscount.round()}% - ${_maxDiscount.round()}%) published to table bookings!'
                : 'Failed to update dynamic discounts',
          ),
          backgroundColor: success ? const Color(0xFF059669) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPublishSlotSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    TimeOfDay selectedStartTime = const TimeOfDay(hour: 13, minute: 0);
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 15, minute: 0);
    int capacity = 30;
    final profile = auth.profile;
    double slotMinDiscount = profile.minDiscount.toDouble().clamp(0.0, 50.0);
    double slotMaxDiscount = profile.maxDiscount.toDouble().clamp(10.0, 70.0);
    if (slotMaxDiscount < slotMinDiscount) slotMaxDiscount = slotMinDiscount;
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
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                shift = 'BREAKFAST';
                                selectedStartTime = const TimeOfDay(hour: 8, minute: 30);
                                selectedEndTime = const TimeOfDay(hour: 10, minute: 30);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: shift == 'BREAKFAST' ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: shift == 'BREAKFAST' ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                                  width: shift == 'BREAKFAST' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.breakfast_dining_rounded, size: 16, color: shift == 'BREAKFAST' ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Breakfast',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: shift == 'BREAKFAST' ? const Color(0xFFEA580C) : const Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '8 - 11 AM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: shift == 'BREAKFAST' ? const Color(0xFFC2410C) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                shift = 'LUNCH';
                                selectedStartTime = const TimeOfDay(hour: 12, minute: 30);
                                selectedEndTime = const TimeOfDay(hour: 14, minute: 30);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: shift == 'LUNCH' ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: shift == 'LUNCH' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                  width: shift == 'LUNCH' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.wb_sunny_rounded, size: 16, color: shift == 'LUNCH' ? const Color(0xFF059669) : const Color(0xFF64748B)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Lunch',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: shift == 'LUNCH' ? const Color(0xFF059669) : const Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '12 - 4 PM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: shift == 'LUNCH' ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                shift = 'DINNER';
                                selectedStartTime = const TimeOfDay(hour: 19, minute: 30);
                                selectedEndTime = const TimeOfDay(hour: 21, minute: 30);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: shift == 'DINNER' ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: shift == 'DINNER' ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                  width: shift == 'DINNER' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.nights_stay_rounded, size: 16, color: shift == 'DINNER' ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dinner',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: shift == 'DINNER' ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    '7 - 11 PM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: shift == 'DINNER' ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

                    const SizedBox(height: 16),

                    // Min & Max Discount Range for this slot
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_graph_rounded, size: 16, color: Color(0xFF0F172A)),
                                  SizedBox(width: 6),
                                  Text(
                                    'DYNAMIC DISCOUNT RANGE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  '${slotMinDiscount.toInt()}% – ${slotMaxDiscount.toInt()}% OFF',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Diners roll a dynamic surprise discount within this range when booking this slot.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                          ),
                          const SizedBox(height: 12),

                          // Quick Preset Pills
                          const Text(
                            'QUICK PRESETS',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildModalPresetChip('10%–20%', 10, 20, slotMinDiscount, slotMaxDiscount, (min, max) {
                                setModalState(() {
                                  slotMinDiscount = min.toDouble();
                                  slotMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('15%–30%', 15, 30, slotMinDiscount, slotMaxDiscount, (min, max) {
                                setModalState(() {
                                  slotMinDiscount = min.toDouble();
                                  slotMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('20%–40%', 20, 40, slotMinDiscount, slotMaxDiscount, (min, max) {
                                setModalState(() {
                                  slotMinDiscount = min.toDouble();
                                  slotMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('25%–50%', 25, 50, slotMinDiscount, slotMaxDiscount, (min, max) {
                                setModalState(() {
                                  slotMinDiscount = min.toDouble();
                                  slotMaxDiscount = max.toDouble();
                                });
                              }),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Dual Min / Max Stepper Cards
                          Row(
                            children: [
                              // Min Floor
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MINIMUM DISCOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: slotMinDiscount > 0
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      slotMinDiscount = (slotMinDiscount - 5).clamp(0.0, 50.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                          Text(
                                            '${slotMinDiscount.toInt()}%',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          InkWell(
                                            onTap: slotMinDiscount < 50
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      slotMinDiscount = (slotMinDiscount + 5).clamp(0.0, 50.0);
                                                      if (slotMaxDiscount < slotMinDiscount) {
                                                        slotMaxDiscount = slotMinDiscount;
                                                      }
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Max Ceiling
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MAXIMUM DISCOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: slotMaxDiscount > slotMinDiscount
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      slotMaxDiscount = (slotMaxDiscount - 5).clamp(slotMinDiscount, 70.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                          Text(
                                            '${slotMaxDiscount.toInt()}%',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                          ),
                                          InkWell(
                                            onTap: slotMaxDiscount < 70
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      slotMaxDiscount = (slotMaxDiscount + 5).clamp(10.0, 70.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                            discountPercentage: slotMinDiscount,
                            minDiscount: slotMinDiscount,
                            maxDiscount: slotMaxDiscount,
                            capacity: capacity,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Table slot published (${slotMinDiscount.toInt()}%–${slotMaxDiscount.toInt()}% OFF)!'
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

  void _showEditSlotSheet(BuildContext context, DailySlotModel slot) {
    HapticFeedback.mediumImpact();
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    int editCapacity = slot.capacity;
    double editMinDiscount = (slot.minDiscount ?? slot.discountPercentage).clamp(0.0, 50.0);
    double editMaxDiscount = (slot.maxDiscount ?? slot.discountPercentage).clamp(10.0, 70.0);
    if (editMaxDiscount < editMinDiscount) editMaxDiscount = editMinDiscount;

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configure Table Slot',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${slot.shift} • ${slot.timeFormatted}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                              onPressed: editCapacity > 5 ? () => setModalState(() => editCapacity -= 5) : null,
                            ),
                            Text('$editCapacity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669), size: 24),
                              onPressed: editCapacity < 150 ? () => setModalState(() => editCapacity += 5) : null,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Slot Min-Max Discount Configuration
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_graph_rounded, size: 16, color: Color(0xFF0F172A)),
                                  SizedBox(width: 6),
                                  Text(
                                    'DYNAMIC DISCOUNT RANGE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  '${editMinDiscount.toInt()}% – ${editMaxDiscount.toInt()}% OFF',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Diners booking this specific slot roll between these min and max discount rates.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                          ),
                          const SizedBox(height: 12),

                          // Quick Preset Pills
                          const Text(
                            'QUICK PRESETS',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildModalPresetChip('10%–20%', 10, 20, editMinDiscount, editMaxDiscount, (min, max) {
                                setModalState(() {
                                  editMinDiscount = min.toDouble();
                                  editMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('15%–30%', 15, 30, editMinDiscount, editMaxDiscount, (min, max) {
                                setModalState(() {
                                  editMinDiscount = min.toDouble();
                                  editMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('20%–40%', 20, 40, editMinDiscount, editMaxDiscount, (min, max) {
                                setModalState(() {
                                  editMinDiscount = min.toDouble();
                                  editMaxDiscount = max.toDouble();
                                });
                              }),
                              const SizedBox(width: 6),
                              _buildModalPresetChip('25%–50%', 25, 50, editMinDiscount, editMaxDiscount, (min, max) {
                                setModalState(() {
                                  editMinDiscount = min.toDouble();
                                  editMaxDiscount = max.toDouble();
                                });
                              }),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Dual Min / Max Stepper Cards
                          Row(
                            children: [
                              // Min Floor
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MINIMUM DISCOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: editMinDiscount > 0
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      editMinDiscount = (editMinDiscount - 5).clamp(0.0, 50.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                          Text(
                                            '${editMinDiscount.toInt()}%',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          InkWell(
                                            onTap: editMinDiscount < 50
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      editMinDiscount = (editMinDiscount + 5).clamp(0.0, 50.0);
                                                      if (editMaxDiscount < editMinDiscount) {
                                                        editMaxDiscount = editMinDiscount;
                                                      }
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Max Ceiling
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MAXIMUM DISCOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: editMaxDiscount > editMinDiscount
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      editMaxDiscount = (editMaxDiscount - 5).clamp(editMinDiscount, 70.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                          Text(
                                            '${editMaxDiscount.toInt()}%',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                          ),
                                          InkWell(
                                            onTap: editMaxDiscount < 70
                                                ? () {
                                                    HapticFeedback.selectionClick();
                                                    setModalState(() {
                                                      editMaxDiscount = (editMaxDiscount + 5).clamp(10.0, 70.0);
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final success = await slotsProvider.updateSlot(
                            slot.slotId,
                            capacity: editCapacity,
                            minDiscount: editMinDiscount,
                            maxDiscount: editMaxDiscount,
                            discountPercentage: editMinDiscount,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Slot updated: ${editMinDiscount.toInt()}%–${editMaxDiscount.toInt()}% OFF, $editCapacity covers'
                                      : 'Failed to update slot',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Slot Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
    final auth = Provider.of<AuthProvider>(context);
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

            // Dynamic Min-Max Slot Discount Range Card
            _buildDynamicDiscountCard(auth),

            const SizedBox(height: 14),

            // Shift Filter Pills & Add Slot
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildShiftChip('ALL', 'All (${slotsProvider.slots.length})', slotsProvider),
                        const SizedBox(width: 8),
                        _buildShiftChip('BREAKFAST', 'Breakfast', slotsProvider),
                        const SizedBox(width: 8),
                        _buildShiftChip('LUNCH', 'Lunch', slotsProvider),
                        const SizedBox(width: 8),
                        _buildShiftChip('DINNER', 'Dinner', slotsProvider),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFFECFDF5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
    final isBreakfast = slot.shift == 'BREAKFAST';
    final isLunch = slot.shift == 'LUNCH';
    final badgeBg = isBreakfast
        ? const Color(0xFFFFF7ED)
        : (isLunch ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF));
    final badgeText = isBreakfast
        ? const Color(0xFFEA580C)
        : (isLunch ? const Color(0xFF059669) : const Color(0xFF2563EB));

    return Container(
      key: ValueKey('liveslot_${slot.slotId}'),
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slot.shift,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
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
              InkWell(
                onTap: () => _showEditSlotSheet(context, slot),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.casino_rounded, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        slot.discountLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.tune_rounded, size: 12, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Delete Slot',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Slot?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      content: Text('Are you sure you want to remove the ${slot.timeFormatted} slot?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.deleteSlot(slot.slotId);
                  }
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                    tooltip: 'Configure Min/Max & Capacity',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditSlotSheet(context, slot),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalPresetChip(String label, int min, int max, double currentMin, double currentMax, void Function(int, int) onTap) {
    final isSelected = currentMin.round() == min && currentMax.round() == max;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(min, max);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicDiscountCard(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _dynamicEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Status & Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _dynamicEnabled ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: _dynamicEnabled ? const Color(0xFF059669) : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Dynamic Min-Max Discount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Set a variable discount range to optimize table bookings',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _dynamicEnabled,
                  activeColor: const Color(0xFF059669),
                  activeTrackColor: const Color(0xFFA7F3D0),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _dynamicEnabled = val);
                  },
                ),
              ],
            ),
          ),

          if (_dynamicEnabled) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strategy Presets Row
                  const Text(
                    'STRATEGY PRESETS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPresetCard('Conservative', '10% – 20%', 10, 20),
                      const SizedBox(width: 8),
                      _buildPresetCard('Balanced', '15% – 30%', 15, 30),
                      const SizedBox(width: 8),
                      _buildPresetCard('Aggressive', '20% – 40%', 20, 40),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Dual Stepper Cards for Min Floor & Max Ceiling
                  const Text(
                    'FINE-TUNE DISCOUNT LIMITS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Min Floor Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'MINIMUM DISCOUNT',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                                  ),
                                  Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF64748B)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: _minDiscount > 5
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _minDiscount = (_minDiscount - 5).clamp(5.0, 30.0);
                                              _rollSampleDiscount();
                                            });
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: const Icon(Icons.remove, size: 16, color: Color(0xFF334155)),
                                    ),
                                  ),
                                  Text(
                                    '${_minDiscount.round()}%',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                  InkWell(
                                    onTap: _minDiscount < 30
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _minDiscount = (_minDiscount + 5).clamp(5.0, 30.0);
                                              if (_maxDiscount < _minDiscount) _maxDiscount = _minDiscount;
                                              _rollSampleDiscount();
                                            });
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: const Icon(Icons.add, size: 16, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Max Ceiling Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'MAXIMUM DISCOUNT',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669), letterSpacing: 0.5),
                                  ),
                                  Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF059669)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: _maxDiscount > _minDiscount
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _maxDiscount = (_maxDiscount - 5).clamp(_minDiscount, 60.0);
                                              _rollSampleDiscount();
                                            });
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: const Icon(Icons.remove, size: 16, color: Color(0xFF334155)),
                                    ),
                                  ),
                                  Text(
                                    '${_maxDiscount.round()}%',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                  ),
                                  InkWell(
                                    onTap: _maxDiscount < 60
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _maxDiscount = (_maxDiscount + 5).clamp(15.0, 60.0);
                                              _rollSampleDiscount();
                                            });
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: const Icon(Icons.add, size: 16, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Simulation Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.casino_outlined, size: 20, color: Color(0xFF0F172A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diner Sample Roll: $_sampleRolledDiscount% OFF',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Random roll dynamically distributed between ${_minDiscount.round()}% and ${_maxDiscount.round()}%.',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rollSampleDiscount());
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0F172A)),
                                SizedBox(width: 4),
                                Text('Re-roll', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSavingDynamic ? null : _saveDynamicDiscount,
                      icon: _isSavingDynamic
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        _isSavingDynamic ? 'Saving Configuration...' : 'Apply Dynamic Settings',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetCard(String title, String range, int min, int max) {
    final isSelected = _minDiscount.round() == min && _maxDiscount.round() == max;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _minDiscount = min.toDouble();
            _maxDiscount = max.toDouble();
            _rollSampleDiscount();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                range,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
