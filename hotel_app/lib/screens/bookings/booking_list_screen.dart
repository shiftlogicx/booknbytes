import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(context, 'ALL', booking.filterStatus == 'ALL'),
                    _buildFilterPill(context, 'CONFIRMED', booking.filterStatus == 'CONFIRMED'),
                    _buildFilterPill(context, 'PENDING', booking.filterStatus == 'PENDING'),
                    _buildFilterPill(context, 'COMPLETED', booking.filterStatus == 'COMPLETED'),
                    _buildFilterPill(context, 'CANCELLED', booking.filterStatus == 'CANCELLED'),
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
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 12),
                          const Text(
                            'No reservations in this status',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: booking.bookings.length,
                      itemBuilder: (context, idx) {
                        final b = booking.bookings[idx];
                        return BookingCard(
                          booking: b,
                          onAccept: () => booking.updateStatus(b.bookingId, 'CONFIRMED'),
                          onReject: () => booking.updateStatus(b.bookingId, 'CANCELLED'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(BuildContext context, String status, bool isSelected) {
    return GestureDetector(
      onTap: () {
        Provider.of<BookingProvider>(context, listen: false).setFilter(status);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : const Color(0xFF334155),
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black87 : Colors.white70,
          ),
        ),
      ),
    );
  }
}
