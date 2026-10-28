import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/glass_nav_dock.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/shift_pulse_bento.dart';
import '../alerts/incoming_booking_alert.dart';
import '../profile/restaurant_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../slots/slot_management_screen.dart';
import '../support/support_screen.dart';
import '../../widgets/partner_walkthrough_modal.dart';
import '../../widgets/reservation_success_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  bool _isAcceptingReservations = true;
  String _activeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<BookingProvider>(context, listen: false)
          .fetchBookings(auth.currentRestaurantId);
      // Automatically detect real device GPS coordinates on launch
      Provider.of<LocationProvider>(context, listen: false).detectCurrentLocation();

      // Show interactive first-time partner walkthrough if not yet seen
      if (!auth.hasSeenTutorial) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            PartnerWalkthroughModal.show(context);
          }
        });
      }
    });
  }

  void _simulateIncomingAlert() async {
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    final mockBooking = BookingModel(
      bookingId: 'bk_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: 'usr_vip_guest',
      restaurantId: 'res_12345xyz',
      restaurantName: 'The Royal Heritage',
      customerName: 'Aditya & Ananya Roy',
      customerPhone: '+91 98230 45678',
      partySize: 4,
      date: DateTime.now().toIso8601String().split('T')[0],
      timeSlot: '20:30',
      status: BookingStatus.pending,
      appliedOffer: 'TASTE20',
      createdAt: DateTime.now(),
    );

    bookingProvider.addNewIncomingBooking(mockBooking);
    notifProvider.triggerIncomingBookingAlert(mockBooking);

    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => IncomingBookingAlertScreen(booking: mockBooking),
      ),
    );

    if (!mounted) return;

    if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🙏 ', style: TextStyle(fontSize: 16)),
              Text('Reservation #${mockBooking.bookingId} Declined • Table Released'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('👨‍🍳✨ ', style: TextStyle(fontSize: 16)),
              Text('Table #${mockBooking.bookingId.replaceAll('bk_', '')} Confirmed · Diner Notified'),
            ],
          ),
          backgroundColor: const Color(0xFF101420),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF00E599), width: 1.2),
          ),
          duration: const Duration(milliseconds: 2500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF101726),
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            LocationPickerBottomSheet.show(context);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      locationProvider.currentLocation.shortLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFF59E0B)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      auth.currentRestaurantName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          // 24x7 Support Hotline & Desk
          IconButton(
            tooltip: 'Partner Helpdesk & FAQs',
            icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF00E599), size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
          // Edit Restaurant Profile
          IconButton(
            tooltip: 'Restaurant Profile & Timings',
            icon: const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RestaurantProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildCurrentTab(),
      extendBody: true, // Allows content to float under the glass dock
      bottomNavigationBar: GlassNavDock(
        currentIndex: _currentNavIndex,
        onTabSelected: (idx) {
          setState(() => _currentNavIndex = idx);
        },
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentNavIndex) {
      case 1:
        return const SlotManagementScreen(isTab: true);
      case 2:
        return const SettingsScreen();
      default:
        return _buildFloorView();
    }
  }

  Widget _buildFloorView() {
    final booking = Provider.of<BookingProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    final allList = booking.bookings;
    final filteredList = _activeFilter == 'ALL'
        ? allList
        : allList.where((b) => b.status.value == _activeFilter).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Command Header Bar
          _buildCommandHeader(locationProvider),

          const SizedBox(height: 16),

          // 2. SHIFT RESERVATION PULSE (Interactive 4-Quadrant Metric Bento)
          ShiftPulseBento(
            todayCount: booking.todayCount,
            confirmedCount: booking.confirmedCount,
            pendingCount: booking.pendingCount,
            expectedCovers: booking.totalCount * 3,
            selectedFilter: _activeFilter,
            onFilterChanged: (filter) {
              setState(() => _activeFilter = filter);
            },
          ),

          const SizedBox(height: 20),

          // 3. LIVE RESERVATION FEED (Direct Diner Action Stream)
          _buildSectionHeader(
            badge: 'GUEST FEED',
            badgeColor: const Color(0xFFF59E0B),
            title: 'Live Reservation Feed',
            subtitle: 'Review, confirm & seat diner arrivals',
            trailingWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${filteredList.length} of ${allList.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter tabs (Pills)
          _buildFilterTabs(allList.length, booking),

          const SizedBox(height: 14),

          // Reservations List
          if (filteredList.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (context, idx) {
                final b = filteredList[idx];
                return BookingCard(
                  booking: b,
                  onAccept: () {
                    booking.updateStatus(b.bookingId, BookingStatus.confirmed);
                    ReservationSuccessDialog.show(context, b);
                  },
                  onReject: () => booking.updateStatus(b.bookingId, BookingStatus.cancelled),
                );
              },
            ),
        ],
      ),
    );
  }

  // 1. Sleek Command Header Bar
  Widget _buildCommandHeader(LocationProvider locationProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131D30), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222F49)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Floor Status Toggle
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _isAcceptingReservations
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                    shape: BoxShape.circle,
                    boxShadow: _isAcceptingReservations
                        ? [
                            const BoxShadow(
                              color: Color(0xFF10B981),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAcceptingReservations ? 'FLOOR IS LIVE' : 'FLOOR PAUSED',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.7,
                          color: _isAcceptingReservations
                              ? const Color(0xFF00E599)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${locationProvider.currentLocation.locality} · Dinner',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isAcceptingReservations,
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isAcceptingReservations = val);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(val ? '👨‍🍳✨ ' : '☕😴 ', style: const TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                val ? 'Floor is LIVE! Accepting diner table bookings' : 'Floor Paused! Tables temporarily paused',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF101420),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: val ? const Color(0xFF00E599) : const Color(0xFF64748B)),
                        ),
                        duration: const Duration(milliseconds: 2000),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: Action Buttons (Ring Bell & Slots)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ring Bell Action Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _simulateIncomingAlert,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ring_volume_rounded, size: 13, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          'Ring',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Hourly Slots & Discounts Action Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentNavIndex = 1);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.percent_rounded, size: 13, color: Color(0xFFA5B4FC)),
                        SizedBox(width: 4),
                        Text(
                          'Slots',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFA5B4FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Consistent, Distinct Section Header
  Widget _buildSectionHeader({
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    Widget? trailingWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (trailingWidget != null) trailingWidget,
      ],
    );
  }

  // Filter Tabs with Animated Indicators
  Widget _buildFilterTabs(int totalCount, BookingProvider booking) {
    final filterOptions = [
      {'key': 'ALL', 'label': 'ALL', 'count': totalCount, 'color': const Color(0xFFF59E0B)},
      {'key': 'PENDING', 'label': 'ACTION NEEDED', 'count': booking.pendingCount, 'color': const Color(0xFFF97316), 'isUrgent': booking.pendingCount > 0},
      {'key': 'CONFIRMED', 'label': 'CONFIRMED', 'count': booking.confirmedCount, 'color': const Color(0xFF00E599)},
      {'key': 'NO_SHOW', 'label': 'NO-SHOW', 'count': booking.noShowCount, 'color': const Color(0xFFEF4444)},
      {'key': 'CANCELLED', 'label': 'CANCELLED', 'count': booking.cancelledCount, 'color': const Color(0xFF64748B)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterOptions.map((opt) {
          final filterKey = opt['key'] as String;
          final isSelected = _activeFilter == filterKey;
          final color = opt['color'] as Color;
          final count = opt['count'] as int;
          final isUrgent = (opt['isUrgent'] as bool?) ?? false;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = filterKey);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : (isUrgent
                          ? color.withValues(alpha: 0.15)
                          : const Color(0xFF131B2E)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isUrgent
                            ? color.withValues(alpha: 0.4)
                            : const Color(0xFF222F49)),
                    width: isUrgent && !isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUrgent && !isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black.withValues(alpha: 0.25)
                            : const Color(0xFF1E283E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.black : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Cartoon empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF101422),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E283E)),
      ),
      child: Column(
        children: [
          const Text('👨‍🍳✨', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          const Text(
            'No reservations in this view',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'New online guest bookings will chime and alert live here',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_activeFilter != 'ALL') ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _activeFilter = 'ALL');
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E283E),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Show All Bookings',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
