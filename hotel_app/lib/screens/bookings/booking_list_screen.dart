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
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table Reservations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Live Guest Management',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
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
            // Filter Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterPill(context, '⚡ ALL', booking.filterStatus == 'ALL', 'ALL'),
                    _buildFilterPill(context, '⏳ PENDING', booking.filterStatus == 'PENDING', 'PENDING'),
                    _buildFilterPill(context, '✅ CONFIRMED', booking.filterStatus == 'CONFIRMED', 'CONFIRMED'),
                    _buildFilterPill(context, '🚫 NO-SHOW', booking.filterStatus == 'NO_SHOW', 'NO_SHOW'),
                    _buildFilterPill(context, '🍽️ COMPLETED', booking.filterStatus == 'COMPLETED', 'COMPLETED'),
                    _buildFilterPill(context, '🕊️ CANCELLED', booking.filterStatus == 'CANCELLED', 'CANCELLED'),
                  ],
                ),
              ),
            ),

            // Bookings List
            Expanded(
              child: booking.bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text('👨‍🍳', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Dining Floor is Sparkling Clean! ✨',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tables prepped and ready for incoming reservations 🍽️',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
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

  Widget _buildFilterPill(BuildContext context, String label, bool isSelected, String filterValue) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Provider.of<BookingProvider>(context, listen: false).setFilter(filterValue);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isSelected ? 0.12 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
