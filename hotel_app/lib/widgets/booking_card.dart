import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const BookingCard({
    super.key,
    required this.booking,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'PENDING';
    final isConfirmed = booking.status == 'CONFIRMED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? Colors.amber.shade700.withOpacity(0.5) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Ref & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${booking.bookingId}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? Colors.green.shade900.withOpacity(0.4)
                      : isPending
                          ? Colors.amber.shade900.withOpacity(0.4)
                          : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConfirmed
                        ? Colors.greenAccent
                        : isPending
                            ? Colors.amberAccent
                            : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Guest & Party Details
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(
                '${booking.partySize} Guests',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${booking.date} at ${booking.timeSlot}',
                style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
            ],
          ),

          if (booking.appliedOffer != null && booking.appliedOffer!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Offer Applied: ${booking.appliedOffer}',
              style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
            ),
          ],

          if (isPending) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReject != null)
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Decline', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                const SizedBox(width: 8),
                if (onAccept != null)
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
