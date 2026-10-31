import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/slots_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/glass_nav_dock.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/shift_pulse_bento.dart';
import '../alerts/incoming_booking_alert.dart';
import '../bookings/booking_list_screen.dart';
import '../discounts/discounts_offers_screen.dart';
import '../profile/restaurant_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../slots/slots_inventory_screen.dart';
import '../support/support_screen.dart';
import '../../widgets/restaurant_walkthrough_modal.dart';

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
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      // Wire up live incoming booking ringing alert callback (Realtime + FCM)
      bookingProvider.onNewBookingAlert = _handleIncomingBookingAlert;

      if (auth.currentRestaurantId.isNotEmpty) {
        bookingProvider.initForRestaurant(auth.currentRestaurantId);
        Provider.of<SlotsProvider>(context, listen: false)
            .loadSlots(auth.currentRestaurantId);
      }
      // Automatically detect real device GPS coordinates on launch
      Provider.of<LocationProvider>(context, listen: false).detectCurrentLocation();

      // Show interactive first-time restaurant walkthrough ONLY during first login
      auth.checkTutorialStatus().then((hasSeen) {
        if (!hasSeen && mounted) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && !auth.hasSeenTutorial) {
              RestaurantWalkthroughModal.show(context);
            }
          });
        }
      });
    });
  }

  void _handleIncomingBookingAlert(BookingModel booking) {
    if (!mounted) return;
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    HapticFeedback.heavyImpact();
    notifProvider.triggerIncomingBookingAlert(booking);
  }

  void _simulateIncomingAlert() async {
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final currentRestId = auth.currentRestaurantId.isNotEmpty
        ? auth.currentRestaurantId
        : 'res_royal_biryani_house';
    final currentRestName = auth.currentRestaurantName.isNotEmpty
        ? auth.currentRestaurantName
        : 'Royal Biryani House';
    final currentUserId = auth.currentUser?.id ?? '6d03741d-db04-4370-bc49-bbb1149a5c33';

    final mockBooking = BookingModel(
      bookingId: 'bk_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      userId: currentUserId,
      restaurantId: currentRestId,
      restaurantName: currentRestName,
      customerName: 'Aditya & Ananya Roy',
      customerPhone: '+91 98230 45678',
      partySize: 4,
      date: DateTime.now().toIso8601String().split('T')[0],
      timeSlot: '20:30',
      status: BookingStatus.pending,
      appliedOffer: 'TASTE20',
      createdAt: DateTime.now(),
    );

    await bookingProvider.addNewIncomingBooking(mockBooking);
    if (!mounted) return;
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
              const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Reservation #${mockBooking.bookingId} Declined · Table Released'),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 18),
              const SizedBox(width: 10),
              Text('Table #${mockBooking.bookingId.replaceAll('bk_', '')} Confirmed · Diner Notified'),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF00E599), width: 1.0),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _currentNavIndex == 0 ? _buildHomeAppBar(auth, locationProvider) : null,
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

  PreferredSizeWidget _buildHomeAppBar(AuthProvider auth, LocationProvider locationProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
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
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Text(
                    locationProvider.currentLocation.shortLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFD97706)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    auth.currentRestaurantName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
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
          tooltip: 'Restaurant Helpdesk & FAQs',
          icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF059669), size: 20),
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
          icon: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestaurantProfileScreen()),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentNavIndex) {
      case 1:
        return const BookingListScreen();
      case 2:
        return const TableSlotsScreen();
      case 3:
        return const DiscountsOffersScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _buildFloorView(); // Initial Home Page: ONLY Shift Reservation Pulse
    }
  }

  // Home Page: Dedicated ONLY to the Shift Reservation Pulse
  Widget _buildFloorView() {
    final booking = Provider.of<BookingProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Command Header Bar
          _buildCommandHeader(locationProvider),

          const SizedBox(height: 20),

          // 2. SHIFT RESERVATION PULSE (Interactive 4-Quadrant Metric Bento)
          ShiftPulseBento(
            todayCount: booking.todayCount,
            confirmedCount: booking.confirmedCount,
            pendingCount: booking.pendingCount,
            expectedCovers: booking.totalCount * 3,
            selectedFilter: _activeFilter,
            onFilterChanged: (filter) {
              setState(() {
                _activeFilter = filter;
                _currentNavIndex = 1; // Switches straight to Bookings tab!
              });
              Provider.of<BookingProvider>(context, listen: false).setFilter(filter);
            },
          ),

          const SizedBox(height: 20),

          // 3. Executive Shift Conversion Bar (CRED/Swiggy luxury style)
          _buildAttendanceBar(booking),

          const SizedBox(height: 24),

          // 4. Clean Quick-Access Destination Cards (CRED style)
          const Text(
            'QUICK OPERATIONS & MANAGEMENT',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          _buildQuickActionCard(
            title: 'Live Table Reservations',
            subtitle: '${booking.todayCount} reservations scheduled today · ${booking.pendingCount} needs action',
            icon: Icons.calendar_month_rounded,
            accentColor: const Color(0xFF00E599),
            badge: '${booking.todayCount} ACTIVE',
            onTap: () => setState(() => _currentNavIndex = 1),
          ),

          const SizedBox(height: 10),

          _buildQuickActionCard(
            title: 'Hourly Table Slots & Capacity',
            subtitle: 'Configure floor tables, limit covers & pause busy slots',
            icon: Icons.table_restaurant_rounded,
            accentColor: const Color(0xFF38BDF8),
            badge: 'SLOTS',
            onTap: () => setState(() => _currentNavIndex = 2),
          ),

          const SizedBox(height: 10),

          _buildQuickActionCard(
            title: 'Discounts & Promotional Offers',
            subtitle: 'Dynamic 10%–40% Off by time slot & custom promo codes',
            icon: Icons.local_offer_rounded,
            accentColor: const Color(0xFFF59E0B),
            badge: 'OFFERS',
            onTap: () => setState(() => _currentNavIndex = 3),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
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
                        ? const Color(0xFF059669)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    boxShadow: _isAcceptingReservations
                        ? [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
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
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
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
                  activeColor: const Color(0xFF059669),
                  activeTrackColor: const Color(0xFF059669).withValues(alpha: 0.25),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isAcceptingReservations = val);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              val ? Icons.radio_button_checked_rounded : Icons.pause_circle_outline_rounded,
                              color: val ? const Color(0xFF00E599) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                val ? 'Floor is Live — accepting table reservations' : 'Floor paused — table bookings temporarily paused',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF0F172A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

          // Right: Action Buttons (Ring Bell & View Bookings)
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ring_volume_rounded, size: 13, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'Ring Bell',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // View Bookings Action Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentNavIndex = 1);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Bookings',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF047857),
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

  Widget _buildAttendanceBar(BookingProvider booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.donut_large_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Text(
                    'ATTENDANCE CONVERSION',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '${booking.attendanceRate.toStringAsFixed(0)}% Seated Rate',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: booking.completedCount > 0 ? booking.completedCount : 8,
                    child: Container(color: const Color(0xFF059669)),
                  ),
                  Expanded(
                    flex: booking.confirmedCount > 0 ? booking.confirmedCount : 3,
                    child: Container(color: const Color(0xFFD97706)),
                  ),
                  Expanded(
                    flex: booking.noShowCount > 0 ? booking.noShowCount : 1,
                    child: Container(color: const Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPulseLegend(const Color(0xFF059669), 'Seated (${booking.completedCount})'),
              _buildPulseLegend(const Color(0xFFD97706), 'Confirmed (${booking.confirmedCount})'),
              _buildPulseLegend(const Color(0xFFDC2626), 'No-Show (${booking.noShowCount})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
