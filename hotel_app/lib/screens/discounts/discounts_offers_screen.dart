import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscountsOffersScreen extends StatefulWidget {
  const DiscountsOffersScreen({super.key});

  @override
  State<DiscountsOffersScreen> createState() => _DiscountsOffersScreenState();
}

class _DiscountsOffersScreenState extends State<DiscountsOffersScreen> {
  String _activeTab = 'SLOTS'; // 'SLOTS' or 'PROMOS'

  // Presets state
  bool _earlyBirdActive = true;
  bool _lateNightActive = true;
  bool _happyHourActive = false;

  // Time slot discounts
  final List<_SlotDiscountConfig> _slotDiscounts = [
    _SlotDiscountConfig(time: '12:00 PM', shift: 'LUNCH', discount: 20, tag: 'Early Bird'),
    _SlotDiscountConfig(time: '12:30 PM', shift: 'LUNCH', discount: 15),
    _SlotDiscountConfig(time: '01:00 PM', shift: 'LUNCH', discount: 10),
    _SlotDiscountConfig(time: '01:30 PM', shift: 'LUNCH', discount: 0, tag: 'Peak Lunch'),
    _SlotDiscountConfig(time: '02:00 PM', shift: 'LUNCH', discount: 25, tag: 'Happy Hour'),
    _SlotDiscountConfig(time: '07:00 PM', shift: 'DINNER', discount: 20, tag: 'Early Dinner'),
    _SlotDiscountConfig(time: '07:30 PM', shift: 'DINNER', discount: 15),
    _SlotDiscountConfig(time: '08:00 PM', shift: 'DINNER', discount: 0, tag: 'Prime Time'),
    _SlotDiscountConfig(time: '08:30 PM', shift: 'DINNER', discount: 0, tag: 'Prime Time'),
    _SlotDiscountConfig(time: '09:00 PM', shift: 'DINNER', discount: 10),
    _SlotDiscountConfig(time: '09:30 PM', shift: 'DINNER', discount: 20),
    _SlotDiscountConfig(time: '10:00 PM', shift: 'DINNER', discount: 30, tag: 'Late Night Deal'),
  ];

  // Custom Promo Codes
  final List<_PromoCodeItem> _promoCodes = [
    _PromoCodeItem(code: 'TASTE20', discount: '20% OFF', description: 'Flat 20% Off on Food Bill', isActive: true, usageCount: 42),
    _PromoCodeItem(code: 'FLAT15', discount: '15% OFF', description: 'Flat 15% Off Total Bill', isActive: true, usageCount: 28),
    _PromoCodeItem(code: 'ROYAL30', discount: '30% OFF', description: 'Special VIP Dinner Promotion', isActive: true, usageCount: 15),
  ];

  void _showAddPromoSheet() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    int selectedDiscount = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101422),
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
                      decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create New Promotional Offer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Drive online bookings with custom promotional codes',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: 'PROMO CODE (e.g. FESTIVE25)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF171E2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'OFFER DESCRIPTION (e.g. 25% Off on Food Bill)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF171E2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            color: isSel ? const Color(0xFFF59E0B) : const Color(0xFF171E2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFFF59E0B) : const Color(0xFF28344E)),
                          ),
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.black : Colors.white,
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
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (codeController.text.trim().isEmpty) return;
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _promoCodes.insert(
                            0,
                            _PromoCodeItem(
                              code: codeController.text.trim().toUpperCase(),
                              discount: '$selectedDiscount% OFF',
                              description: descController.text.trim().isEmpty
                                  ? 'Flat $selectedDiscount% Off'
                                  : descController.text.trim(),
                              isActive: true,
                              usageCount: 0,
                            ),
                          );
                        });
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
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discounts & Promotions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Dynamic Slot Discounts & Promo Offers',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFF59E0B)),
            tooltip: 'Add Promo Code',
            onPressed: _showAddPromoSheet,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Mode Switcher: Hourly Slot Discounts vs Promo Codes
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF222F49)),
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
                accentColor: const Color(0xFFF59E0B),
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
                accentColor: const Color(0xFF818CF8),
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
                accentColor: const Color(0xFF00E599),
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
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFFF59E0B)),
                    label: const Text('Add Offer', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E283E) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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
        color: const Color(0xFF101422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? accentColor.withValues(alpha: 0.4) : const Color(0xFF1E283E),
          width: isActive ? 1.2 : 1.0,
        ),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
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
        color: const Color(0xFF101422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E283E)),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (slot.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slot.tag!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: slot.discount > 0
                      ? const Color(0xFF00E599).withValues(alpha: 0.15)
                      : const Color(0xFF1E283E),
                  borderRadius: BorderRadius.circular(8),
                  border: slot.discount > 0
                      ? Border.all(color: const Color(0xFF00E599).withValues(alpha: 0.35))
                      : null,
                ),
                child: Text(
                  slot.discount > 0 ? '${slot.discount}% OFF' : 'FULL PRICE (0%)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: slot.discount > 0 ? const Color(0xFF00E599) : const Color(0xFF64748B),
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
                        color: isSel ? const Color(0xFF00E599) : const Color(0xFF151C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xFF00E599) : const Color(0xFF222B3D),
                        ),
                      ),
                      child: Text(
                        val == 0 ? 'No Offer' : '$val%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                          color: isSel ? Colors.black : const Color(0xFF94A3B8),
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
        color: const Color(0xFF101422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E283E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer_rounded, size: 18, color: Color(0xFFFBBF24)),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E599).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promo.discount,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF00E599)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${promo.description} · ${promo.usageCount} Diners Used',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),

          Switch.adaptive(
            value: promo.isActive,
            activeColor: const Color(0xFF00E599),
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
