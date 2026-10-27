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
import '../../widgets/live_dining_queue.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/stats_card.dart';
import '../alerts/incoming_booking_alert.dart';
import '../bookings/booking_list_screen.dart';
import '../profile/restaurant_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../slots/slot_management_screen.dart';
import '../support/support_screen.dart';
import '../../widgets/partner_walkthrough_modal.dart';

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
          content: Text('Reservation #${mockBooking.bookingId} Declined'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // Audio Test Alert Chime Button
          IconButton(
            tooltip: 'Test Booking Audio Alert',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDC2626).withOpacity(0.2),
                    const Color(0xFF991B1B).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFFF87171), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Test Alarm',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            onPressed: _simulateIncomingAlert,
          ),
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
        return const BookingListScreen();
      case 2:
        return const SlotManagementScreen(isTab: true);
      case 3:
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Service Control Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isAcceptingReservations
                            ? const Color(0xFF10B981).withOpacity(0.15)
                            : const Color(0xFF64748B).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isAcceptingReservations
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      child: Icon(
                        _isAcceptingReservations
                            ? Icons.table_restaurant_rounded
                            : Icons.pause_circle_filled_rounded,
                        size: 20,
                        color: _isAcceptingReservations
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAcceptingReservations ? 'Accepting Reservations' : 'Floor Temporarily Paused',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${locationProvider.currentLocation.locality} · Dinner Service',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isAcceptingReservations,
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isAcceptingReservations = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Priority Alarm Active Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.12),
                  const Color(0xFF131B2E),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ring_volume_rounded, color: Color(0xFFFBBF24), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Table Ringing Active',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFFFDE68A),
                        ),
                      ),
                      Text(
                        'Instant audible bell & full-screen alert for incoming reservations',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _simulateIncomingAlert,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Ring',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic Slots & Hourly Discounts Quick Banner
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentNavIndex = 2);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E1B4B), // Indigo luxury tint
                    Color(0xFF101726),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.percent_rounded, color: Color(0xFFA5B4FC), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Hourly Slots & Discounts',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure 10%-40% OFF & table limits per slot',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFA5B4FC), size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Luxury Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatsCard(
                title: 'TODAY RESERVATIONS',
                value: '${booking.todayCount}',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                trend: '+18% today',
              ),
              StatsCard(
                title: 'CONFIRMED TABLES',
                value: '${booking.confirmedCount}',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                subtitle: '85% occupancy',
              ),
              StatsCard(
                title: 'PENDING ALERTS',
                value: '${booking.pendingCount}',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF97316),
                subtitle: 'Requires action',
              ),
              StatsCard(
                title: 'EXPECTED COVERS',
                value: '${booking.totalCount * 3}',
                icon: Icons.groups_rounded,
                color: const Color(0xFF6366F1),
                subtitle: 'Evening peak',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Live Dining Queue & Capacity Surge Meter
          const LiveDiningQueueTracker(),

          const SizedBox(height: 22),

          // Live Reservations Section Header & Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Floor Stream',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredList.length} of ${allList.length}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'PENDING', 'CONFIRMED', 'CANCELLED'].map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeFilter = filter);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF222F49),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Reservations List
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222F49)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF475569)),
                  SizedBox(height: 8),
                  Text(
                    'No reservations in this view',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (context, idx) {
                final b = filteredList[idx];
                return BookingCard(
                  booking: b,
                  onAccept: () => booking.updateStatus(b.bookingId, BookingStatus.confirmed),
                  onReject: () => booking.updateStatus(b.bookingId, BookingStatus.cancelled),
                );
              },
            ),
        ],
      ),
    );
  }
}
