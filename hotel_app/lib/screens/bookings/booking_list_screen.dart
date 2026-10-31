import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/reservation_success_dialog.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

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
            const Text(
              'Table Reservations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${booking.totalCount} Total Entries · Live Floor Console',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Reservations',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              booking.loadBookings(auth.currentRestaurantId);
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
                      label: 'No-Show',
                      count: booking.noShowCount,
                      dotColor: const Color(0xFFDC2626),
                      isSelected: booking.filterStatus == 'NO_SHOW',
                      filterValue: 'NO_SHOW',
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

            // Bookings List
            Expanded(
              child: booking.bookings.isEmpty
                  ? Center(
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
                            const Text(
                              'No Reservations in this Queue',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Incoming bookings will automatically populate here via real-time floor sync.',
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
                                booking.loadBookings(auth.currentRestaurantId);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Refresh Floor Feed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: booking.bookings.length,
                      itemBuilder: (context, idx) {
                        final b = booking.bookings[idx];
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
