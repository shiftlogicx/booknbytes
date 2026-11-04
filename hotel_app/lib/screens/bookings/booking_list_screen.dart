import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/reservation_success_dialog.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final booking = Provider.of<BookingProvider>(context, listen: false);
    final restId = auth.currentRestaurantId;
    if (restId.isNotEmpty) {
      booking.loadBookings(restId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFEAECEF), width: 0.8),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Table Reservations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '${booking.totalCount} Total Entries · ${auth.currentRestaurantName.isNotEmpty ? auth.currentRestaurantName : "Live Floor Console"}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Reservations',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Refined Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEAECEF), width: 0.8),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildPill(
                      context,
                      label: 'All',
                      count: booking.totalCount,
                      dotColor: const Color(0xFF0F172A),
                      isSelected: booking.filterStatus == 'ALL',
                      filterValue: 'ALL',
                    ),
                    _buildPill(
                      context,
                      label: 'Pending',
                      count: booking.pendingCount,
                      dotColor: const Color(0xFFD97706),
                      isSelected: booking.filterStatus == 'PENDING',
                      filterValue: 'PENDING',
                    ),
                    _buildPill(
                      context,
                      label: 'Confirmed',
                      count: booking.confirmedCount,
                      dotColor: const Color(0xFF059669),
                      isSelected: booking.filterStatus == 'CONFIRMED',
                      filterValue: 'CONFIRMED',
                    ),
                    _buildPill(
                      context,
                      label: 'Seated',
                      count: booking.completedCount,
                      dotColor: const Color(0xFF4F46E5),
                      isSelected: booking.filterStatus == 'COMPLETED',
                      filterValue: 'COMPLETED',
                    ),
                    _buildPill(
                      context,
                      label: 'Cancelled',
                      count: booking.cancelledCount,
                      dotColor: const Color(0xFF94A3B8),
                      isSelected: booking.filterStatus == 'CANCELLED',
                      filterValue: 'CANCELLED',
                    ),
                  ],
                ),
              ),
            ),

            // Bookings List with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  final restId = auth.currentRestaurantId;
                  if (restId.isNotEmpty) {
                    await booking.loadBookings(restId);
                  }
                },
                color: const Color(0xFF0F172A),
                backgroundColor: Colors.white,
                child: booking.bookings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.table_restaurant_rounded,
                                      size: 32,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    booking.filterStatus == 'ALL'
                                        ? 'No Reservations in this Queue'
                                        : 'No ${booking.filterStatus} Reservations',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Incoming bookings from the Customer App or Admin Portal will automatically stream here in real time.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _refreshData();
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Refresh Floor Feed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: booking.bookings.length,
                        itemBuilder: (context, idx) {
                          final b = booking.bookings[idx];
                          return BookingCard(
                            key: ValueKey('booking_${b.bookingId}'),
                            booking: b,
                            onAccept: () async {
                              if (!booking.isFloorOperational) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot accept booking: Floor is currently paused.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }
                              if (!b.isCurrentOrUpcomingForToday) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot accept past bookings. Only current/upcoming reservations for today can be confirmed.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }
                              final success = await booking.acceptBooking(b.bookingId);
                              if (success && context.mounted) {
                                ReservationSuccessDialog.show(context, b);
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required String label,
    required int count,
    required Color dotColor,
    required bool isSelected,
    required String filterValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Provider.of<BookingProvider>(context, listen: false).setFilter(filterValue);
          },
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
