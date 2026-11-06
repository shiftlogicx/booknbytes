import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/slots_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/glass_nav_dock.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/shift_pulse_bento.dart';
import '../bookings/booking_list_screen.dart';
import '../profile/restaurant_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../slots/slots_inventory_screen.dart';
import '../alerts/incoming_booking_alert.dart';
import '../../widgets/restaurant_walkthrough_modal.dart';
import '../../services/app_update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  String _activeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      // Check for dynamic optional or mandatory app updates from Supabase
      AppUpdateService.checkVersion(context);

      // Wire up live incoming booking ringing alert callback (Realtime + FCM)
      bookingProvider.onNewBookingAlert = _handleIncomingBookingAlert;

      if (auth.currentRestaurantId.isNotEmpty) {
        bookingProvider.initForRestaurant(auth.currentRestaurantId);
        Provider.of<SlotsProvider>(context, listen: false)
            .loadSlots(auth.currentRestaurantId);
      }
      // Automatically detect real device GPS coordinates on launch
      Provider.of<LocationProvider>(context, listen: false).detectCurrentLocation();

      // Show interactive first-time restaurant walkthrough ONLY when user signs up newly
      auth.checkTutorialStatus().then((shouldShow) {
        if (shouldShow && mounted) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && auth.shouldShowTutorial) {
              RestaurantWalkthroughModal.show(context);
            }
          });
        }
      });
    });
  }

  void _handleIncomingBookingAlert(BookingModel booking) {
    if (!mounted) return;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    // 1. Only alert if floor is operational
    if (!bookingProvider.isFloorOperational) {
      debugPrint('[DashboardScreen] Floor is paused; suppressing incoming booking alert');
      return;
    }
    // 2. Only alert if booking is current or upcoming for today (no past bookings)
    if (!booking.isCurrentOrUpcomingForToday) {
      debugPrint('[DashboardScreen] Booking is in the past or not for today; suppressing alert');
      return;
    }

    HapticFeedback.heavyImpact();
    // Launch priority full-screen ringing alert
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingBookingAlertScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildFloorTab(),
          const BookingListScreen(),
          const TableSlotsScreen(),
          const SettingsScreen(),
        ],
      ),
      extendBody: true, // Allows content to float under the glass dock
      bottomNavigationBar: GlassNavDock(
        currentIndex: _currentNavIndex,
        onTabSelected: (idx) {
          setState(() => _currentNavIndex = idx);
        },
      ),
    );
  }

  Widget _buildFloorTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildHomeAppBar(),
      body: _buildFloorView(),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      titleSpacing: 16,
      title: Consumer2<AuthProvider, LocationProvider>(
        builder: (context, auth, locationProvider, _) {
          return InkWell(
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
          );
        },
      ),
      actions: [
        // Restaurant Profile Avatar / Icon
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RestaurantProfileScreen()),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Home Page: Dedicated ONLY to the Shift Reservation Pulse
  Widget _buildFloorView() {
    return Consumer2<BookingProvider, LocationProvider>(
      builder: (context, booking, locationProvider, _) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Command Header Bar
              _buildCommandHeader(locationProvider, booking),

              const SizedBox(height: 20),

              // 2. SHIFT RESERVATION PULSE (Interactive 4-Quadrant Metric Bento)
              ShiftPulseBento(
                todayCount: booking.todayCount,
                confirmedCount: booking.todayCount > 0 ? booking.todayConfirmedCount : booking.confirmedCount,
                pendingCount: booking.pendingCount,
                expectedCovers: booking.todayCount > 0 ? booking.todayExpectedCovers : booking.totalExpectedCovers,
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
                title: 'Settings & Restaurant Rules',
                subtitle: 'Manage auto-confirm, instant ring alerts & opening hours',
                icon: Icons.tune_rounded,
                accentColor: const Color(0xFF8B5CF6),
                badge: 'SETTINGS',
                onTap: () => setState(() => _currentNavIndex = 3),
              ),
            ],
          ),
        );
      },
    );
  }


  // 1. Sleek Command Header Bar
  Widget _buildCommandHeader(LocationProvider locationProvider, BookingProvider bookingProvider) {
    final isLive = bookingProvider.isFloorOperational;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Row: Status Indicator, Title & Switch Toggle
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                  boxShadow: isLive
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? 'FLOOR IS LIVE' : 'FLOOR PAUSED',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                        color: isLive
                            ? const Color(0xFF047857)
                            : const Color(0xFFDC2626),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${locationProvider.currentLocation.locality} · Dinner Shift',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // High-Contrast Interactive Toggle Button with Explicit Text
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final val = !isLive;
                  bookingProvider.setFloorOperational(val);
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
                              val ? 'Floor is Live — accepting table reservations' : 'Floor paused — reservations temporarily paused',
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
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLive ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'LIVE' : 'PAUSED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isLive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isLive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                        size: 14,
                        color: isLive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.7, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Secondary Row: View Reservations
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _currentNavIndex = 1);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 8),
                    Text(
                      'View Today\'s Reservations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
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
                  booking.completedCount + booking.noShowCount == 0
                      ? 'No Finished Shifts'
                      : '${booking.attendanceRate.toStringAsFixed(0)}% Seated Rate',
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
              child: (booking.completedCount == 0 && booking.confirmedCount == 0 && booking.noShowCount == 0)
                  ? Container(
                      color: const Color(0xFFE2E8F0),
                    )
                  : Row(
                      children: [
                        if (booking.completedCount > 0)
                          Expanded(
                            flex: booking.completedCount,
                            child: Container(color: const Color(0xFF059669)),
                          ),
                        if (booking.confirmedCount > 0)
                          Expanded(
                            flex: booking.confirmedCount,
                            child: Container(color: const Color(0xFFD97706)),
                          ),
                        if (booking.noShowCount > 0)
                          Expanded(
                            flex: booking.noShowCount,
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
