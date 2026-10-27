import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/reservation_success_dialog.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table Reservations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Live Guest Management',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: () {
              HapticFeedback.lightImpact();
              booking.fetchBookings('res_12345xyz');
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                              color: const Color(0xFF131B2E),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF28344E), width: 1.5),
                            ),
                            child: const Text('👨‍🍳', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Dining Floor is Sparkling Clean! ✨',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tables prepped and ready for incoming reservations 🍽️',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
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
          color: isSelected ? const Color(0xFF00E599) : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E599) : const Color(0xFF222F49),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
