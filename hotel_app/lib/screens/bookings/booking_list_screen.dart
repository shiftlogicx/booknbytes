import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';

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
                    _buildFilterPill(context, 'ALL', booking.filterStatus == 'ALL'),
                    _buildFilterPill(context, 'PENDING', booking.filterStatus == 'PENDING'),
                    _buildFilterPill(context, 'CONFIRMED', booking.filterStatus == 'CONFIRMED'),
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
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: Color(0xFF131B2E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.dinner_dining_rounded, size: 40, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No reservations in this status',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Reservations from guest bookings will appear here',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(BuildContext context, String status, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Provider.of<BookingProvider>(context, listen: false).setFilter(status);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF222F49),
          ),
        ),
        child: Text(
          status,
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
