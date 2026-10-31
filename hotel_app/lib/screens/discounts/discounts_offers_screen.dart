import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/slots_provider.dart';
import '../../services/supabase_service.dart';

class DiscountsOffersScreen extends StatefulWidget {
  const DiscountsOffersScreen({super.key});

  @override
  State<DiscountsOffersScreen> createState() => _DiscountsOffersScreenState();
}

class _DiscountsOffersScreenState extends State<DiscountsOffersScreen> {
  String _activeTab = 'SLOTS'; // 'SLOTS' or 'PROMOS'

  // Presets start clean slate (0% until owner enables)
  bool _earlyBirdActive = false;
  bool _lateNightActive = false;
  bool _happyHourActive = false;
  bool _initialized = false;

  final List<_SlotDiscountConfig> _slotDiscounts = [
    _SlotDiscountConfig(time: '12:00 PM', shift: 'LUNCH', discount: 0, tag: 'Early Bird'),
    _SlotDiscountConfig(time: '12:30 PM', shift: 'LUNCH', discount: 0),
    _SlotDiscountConfig(time: '01:00 PM', shift: 'LUNCH', discount: 0),
    _SlotDiscountConfig(time: '01:30 PM', shift: 'LUNCH', discount: 0),
    _SlotDiscountConfig(time: '02:00 PM', shift: 'LUNCH', discount: 0, tag: 'Happy Hour'),
    _SlotDiscountConfig(time: '02:30 PM', shift: 'LUNCH', discount: 0, tag: 'Happy Hour'),
    _SlotDiscountConfig(time: '07:00 PM', shift: 'DINNER', discount: 0, tag: 'Early Bird'),
    _SlotDiscountConfig(time: '07:30 PM', shift: 'DINNER', discount: 0),
    _SlotDiscountConfig(time: '08:00 PM', shift: 'DINNER', discount: 0),
    _SlotDiscountConfig(time: '08:30 PM', shift: 'DINNER', discount: 0),
    _SlotDiscountConfig(time: '09:00 PM', shift: 'DINNER', discount: 0),
    _SlotDiscountConfig(time: '09:30 PM', shift: 'DINNER', discount: 0),
    _SlotDiscountConfig(time: '10:00 PM', shift: 'DINNER', discount: 0, tag: 'Late Night Deal'),
  ];

  final List<_PromoCodeItem> _promoCodes = [];
  bool _isPublishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _promoCodes.clear();
      for (final o in auth.profile.activeOffers) {
        _promoCodes.add(
          _PromoCodeItem(
            code: o['code']?.toString() ?? 'PROMO',
            discount: '${o['discount_percent'] ?? 20}% OFF',
            description: o['description']?.toString() ?? 'Promotional table reservation deal',
            isActive: true,
            usageCount: 0,
          ),
        );
      }
      _loadSavedHourlyDiscounts();
      _initialized = true;
    }
  }

  Future<void> _loadSavedHourlyDiscounts() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restId = auth.currentRestaurantId;
    if (restId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('hourly_discounts_$restId');
      if (savedStr != null) {
        final decoded = jsonDecode(savedStr) as Map<String, dynamic>;
        setState(() {
          _earlyBirdActive = decoded['early_bird'] == true;
          _lateNightActive = decoded['late_night'] == true;
          _happyHourActive = decoded['happy_hour'] == true;
          final discountsMap = decoded['discounts'] as Map<String, dynamic>?;
          if (discountsMap != null) {
            for (var s in _slotDiscounts) {
              if (discountsMap.containsKey(s.time)) {
                s.discount = (discountsMap[s.time] as num).toInt();
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved hourly discounts: $e');
    }
  }

  Future<void> _publishHourlyDiscounts() async {
    HapticFeedback.heavyImpact();
    setState(() => _isPublishing = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);
    final restId = auth.currentRestaurantId;

    try {
      // 1. Save configuration to device persistent storage so it never vanishes
      final prefs = await SharedPreferences.getInstance();
      final discountsMap = {for (var s in _slotDiscounts) s.time: s.discount};
      final dataToSave = {
        'early_bird': _earlyBirdActive,
        'late_night': _lateNightActive,
        'happy_hour': _happyHourActive,
        'discounts': discountsMap,
      };
      await prefs.setString('hourly_discounts_$restId', jsonEncode(dataToSave));

      // 2. Apply to existing table slots in database
      int updatedCount = 0;
      for (final slot in slotsProvider.slots) {
        if (slot.startDatetime != null && slot.slotId.isNotEmpty) {
          final timeStr = DateFormat('hh:mm a').format(slot.startDatetime!);
          final matchingConfig = _slotDiscounts.firstWhere(
            (c) => c.time == timeStr,
            orElse: () => _SlotDiscountConfig(time: '', shift: '', discount: -1),
          );
          if (matchingConfig.discount >= 0) {
            try {
              await SupabaseService().updateDailySlot(slot.slotId, {
                'discount_percentage': matchingConfig.discount.toDouble(),
              });
              updatedCount++;
            } catch (e) {
              debugPrint('Failed to update slot ${slot.slotId}: $e');
            }
          }
        }
      }

      // Reload live slots
      if (restId.isNotEmpty) {
        await slotsProvider.loadSlots(restId);
      }

      setState(() => _isPublishing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    updatedCount > 0
                        ? 'Hourly discounts published! Applied to $updatedCount live floor slots.'
                        : 'Hourly discounts published and saved successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isPublishing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish hourly discounts: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddPromoSheet() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    int selectedDiscount = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                  const Text(
                    'Create New Promotional Offer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Drive online bookings with custom promotional codes',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: 'PROMO CODE (e.g. FESTIVE25)',
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'OFFER DESCRIPTION (e.g. 25% Off on Food Bill)',
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'DISCOUNT VALUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [10, 15, 20, 25, 30, 40].map((pct) {
                      final isSel = selectedDiscount == pct;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedDiscount = pct);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (codeController.text.trim().isEmpty) return;
                        HapticFeedback.mediumImpact();
                        final newCode = codeController.text.trim().toUpperCase();
                        final newDesc = descController.text.trim().isEmpty
                            ? 'Flat $selectedDiscount% Off'
                            : descController.text.trim();

                        setState(() {
                          _promoCodes.insert(
                            0,
                            _PromoCodeItem(
                              code: newCode,
                              discount: '$selectedDiscount% OFF',
                              description: newDesc,
                              isActive: true,
                              usageCount: 0,
                            ),
                          );
                        });

                        // Sync to Supabase active_offers
                        try {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final offers = List<Map<String, dynamic>>.from(auth.profile.activeOffers);
                          offers.add({
                            'code': newCode,
                            'description': newDesc,
                            'discount_percent': selectedDiscount,
                          });
                          await SupabaseService().updateActiveOffers(auth.currentRestaurantId, offers);
                          auth.refreshRestaurantData();
                        } catch (e) {
                          debugPrint('Error syncing offer to Supabase: $e');
                        }

                        Navigator.of(context).pop();
                      },
                      child: const Text('Publish Promo Offer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Discounts & Promotions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Dynamic Slot Discounts & Promo Offers',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (_activeTab == 'SLOTS')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: _isPublishing ? null : _publishHourlyDiscounts,
                icon: _isPublishing
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)))
                    : const Icon(Icons.cloud_upload_rounded, size: 16, color: Color(0xFF059669)),
                label: Text(
                  _isPublishing ? 'Publishing...' : 'Publish',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFD97706)),
              tooltip: 'Add Promo Code',
              onPressed: _showAddPromoSheet,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            // Mode Switcher: Hourly Slot Discounts vs Promo Codes
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'Hourly Slot Deals',
                      isSelected: _activeTab == 'SLOTS',
                      icon: Icons.access_time_rounded,
                      onTap: () => setState(() => _activeTab = 'SLOTS'),
                    ),
                  ),
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'Active Promo Codes (${_promoCodes.length})',
                      isSelected: _activeTab == 'PROMOS',
                      icon: Icons.local_offer_rounded,
                      onTap: () => setState(() => _activeTab = 'PROMOS'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_activeTab == 'SLOTS') ...[
              // Fast Presets Header
              const Text(
                'QUICK PROMOTIONAL SURGE PRESETS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              // 3 Preset Cards
              _buildPresetCard(
                title: '🌅 Early Bird Offer (25% OFF)',
                subtitle: 'Applies 25% Off to 12:00 PM & 07:00 PM slots',
                isActive: _earlyBirdActive,
                accentColor: const Color(0xFFD97706),
                onToggle: (val) {
                  setState(() => _earlyBirdActive = val);
                  _toggleSlotPreset('Early Bird', 25, val);
                },
              ),
              const SizedBox(height: 8),
              _buildPresetCard(
                title: '🌙 Late Night Deal (30% OFF)',
                subtitle: 'Applies 30% Off to slots after 10:00 PM',
                isActive: _lateNightActive,
                accentColor: const Color(0xFF4F46E5),
                onToggle: (val) {
                  setState(() => _lateNightActive = val);
                  _toggleSlotPreset('Late Night Deal', 30, val);
                },
              ),
              const SizedBox(height: 8),
              _buildPresetCard(
                title: '⚡ Afternoon Happy Hour (20% OFF)',
                subtitle: 'Applies 20% Off to 02:00 PM – 04:00 PM slots',
                isActive: _happyHourActive,
                accentColor: const Color(0xFF059669),
                onToggle: (val) {
                  setState(() => _happyHourActive = val);
                  _toggleSlotPreset('Happy Hour', 20, val);
                },
              ),

              const SizedBox(height: 20),

              // Hourly Slot Discounts Configuration List
              const Text(
                'HOURLY SLOT DISCOUNT CONFIGURATION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              ..._slotDiscounts.map((slot) => _buildHourlyDiscountCard(slot)),

              const SizedBox(height: 16),

              // Publish Hourly Discounts Action Card & Button
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.save_rounded, size: 18, color: Color(0xFF059669)),
                        SizedBox(width: 8),
                        Text(
                          'Apply & Publish Configuration',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Publishes and preserves your hourly discount settings across all active floor table slots.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isPublishing ? null : _publishHourlyDiscounts,
                        icon: _isPublishing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          _isPublishing ? 'Publishing Hourly Discounts...' : 'Publish Hourly Discounts',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Promo Codes View
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PUBLISHED PROMOTIONAL CODES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
                  ),
                  TextButton.icon(
                    onPressed: _showAddPromoSheet,
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFFD97706)),
                    label: const Text('Add Offer', style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_promoCodes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No promotional offers created yet',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Start with a clean slate. Tap "+ Add Offer" to publish custom promo discount codes for your diners.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showAddPromoSheet,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create First Promo Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                ..._promoCodes.map((promo) => _buildPromoCodeCard(promo)),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSlotPreset(String tag, int percentage, bool enable) {
    HapticFeedback.mediumImpact();
    for (var s in _slotDiscounts) {
      if (s.tag == tag) {
        s.discount = enable ? percentage : 0;
      }
    }
  }

  Widget _buildSubTabButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required bool isActive,
    required Color accentColor,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? accentColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
          width: isActive ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            activeColor: accentColor,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onToggle(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDiscountCard(_SlotDiscountConfig slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    slot.time,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  if (slot.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        slot.tag!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: slot.discount > 0
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: slot.discount > 0
                      ? Border.all(color: const Color(0xFFA7F3D0))
                      : null,
                ),
                child: Text(
                  slot.discount > 0 ? '${slot.discount}% OFF' : 'FULL PRICE (0%)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: slot.discount > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Percentage Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [0, 10, 15, 20, 25, 30, 40].map((val) {
                final isSel = slot.discount == val;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => slot.discount = val);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        val == 0 ? 'No Offer' : '$val%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                          color: isSel ? Colors.white : const Color(0xFF475569),
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
    );
  }

  Widget _buildPromoCodeCard(_PromoCodeItem promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(Icons.local_offer_rounded, size: 18, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        promo.code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          promo.discount,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${promo.description} · ${promo.usageCount} Diners Used',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),

          Switch.adaptive(
            value: promo.isActive,
            activeColor: const Color(0xFF059669),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => promo.isActive = val);
            },
          ),
        ],
      ),
    );
  }
}

class _SlotDiscountConfig {
  final String time;
  final String shift;
  int discount;
  final String? tag;

  _SlotDiscountConfig({
    required this.time,
    required this.shift,
    required this.discount,
    this.tag,
  });
}

class _PromoCodeItem {
  final String code;
  final String discount;
  final String description;
  bool isActive;
  final int usageCount;

  _PromoCodeItem({
    required this.code,
    required this.discount,
    required this.description,
    required this.isActive,
    required this.usageCount,
  });
}
