import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/booking_card.dart';
import '../alerts/incoming_booking_alert.dart';
import '../bookings/booking_list_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<BookingProvider>(context, listen: false)
          .fetchBookings(auth.currentRestaurantId);
    });
  }

  void _simulateIncomingAlert() {
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    final mockBooking = BookingModel(
      bookingId: 'bk_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: 'usr_live_guest',
      restaurantId: 'res_12345xyz',
      restaurantName: 'Mahesh Lunch Home',
      partySize: 4,
      date: DateTime.now().toIso8601String().split('T')[0],
      timeSlot: '20:00',
      status: BookingStatus.pending,
      appliedOffer: 'flat_10',
      createdAt: DateTime.now(),
    );

    bookingProvider.addNewIncomingBooking(mockBooking);
    notifProvider.triggerIncomingBookingAlert(mockBooking);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => IncomingBookingAlertScreen(booking: mockBooking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.currentRestaurantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                SizedBox(width: 4),
                Text(
                  'FCM Ringing Terminal Active',
                  style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Simulate MyGate Alert Test Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.ring_volume_rounded, color: Colors.redAccent, size: 14),
                  SizedBox(width: 4),
                  Text('Test Alert', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            tooltip: 'Simulate MyGate Full-Screen Ringing Intent',
            onPressed: _simulateIncomingAlert,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (idx) => setState(() => _currentNavIndex = idx),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Terminal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant_rounded),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentNavIndex) {
      case 1:
        return const BookingListScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildTerminalView();
    }
  }

  Widget _buildTerminalView() {
    final booking = Provider.of<BookingProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for MyGate alert verification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF881337), Color(0xFF4C0519)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.vibration_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MyGate-Style Full Screen Ringing',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      Text(
                        'Wakes locked screen on incoming Firestore bookings via FCM data payload.',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _simulateIncomingAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Trigger Ring',
                    style: TextStyle(color: Color(0xFF881337), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stats Grid
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
                color: Colors.orangeAccent,
              ),
              StatsCard(
                title: 'CONFIRMED TABLES',
                value: '${booking.confirmedCount}',
                icon: Icons.check_circle_rounded,
                color: Colors.greenAccent,
              ),
              StatsCard(
                title: 'PENDING ALERTS',
                value: '${booking.pendingCount}',
                icon: Icons.pending_actions_rounded,
                color: Colors.amberAccent,
              ),
              StatsCard(
                title: 'TOTAL COVERS',
                value: '${booking.totalCount * 3}',
                icon: Icons.people_alt_rounded,
                color: Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's incoming reservations section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Reservation Stream',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${booking.bookings.length} Bookings',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (booking.bookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No active reservations', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: booking.bookings.length,
              itemBuilder: (context, idx) {
                final b = booking.bookings[idx];
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
