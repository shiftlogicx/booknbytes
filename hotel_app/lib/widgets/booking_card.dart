import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const BookingCard({
    super.key,
    required this.booking,
    this.onAccept,
    this.onDecline,
  });

  void _markSeated(BuildContext context) {
    HapticFeedback.mediumImpact();
    Provider.of<BookingProvider>(context, listen: false).markCompleted(booking.bookingId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${booking.customerName ?? "Diner"} Seated · Service active',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = booking.isPending;
    final isConfirmed = booking.isConfirmed;
    final isNoShow = booking.isNoShow;
    final isCompleted = booking.isCompleted;

    final Color statusColor = isConfirmed
        ? const Color(0xFF059669)
        : isNoShow
            ? const Color(0xFFDC2626)
            : isCompleted
                ? const Color(0xFF2563EB)
                : isPending
                    ? const Color(0xFFD97706)
                    : const Color(0xFF64748B);

    final String timeSlot = booking.timeSlot;
    final bool isDinner = timeSlot.compareTo('17:00') >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? const Color(0xFFD97706).withValues(alpha: 0.6)
              : isNoShow
                  ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (isPending)
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status & Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '#${booking.bookingId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dining service badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDinner
                              ? const Color(0xFFEEF2FF)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDinner
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDinner ? Icons.nightlife_rounded : Icons.wb_sunny_rounded,
                              size: 11,
                              color: isDinner ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDinner ? 'Dinner' : 'Lunch',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDinner ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNoShow ? 'NO-SHOW' : booking.status.value.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Body: Diner Details & Time
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name & Verified Pill
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                (booking.customerName ?? 'G')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    booking.customerName ?? 'Guest Diner',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF059669),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.customerPhone ?? '+91 • Verified Restaurant Guest',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Time Slot Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SLOT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.timeSlot,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Table Attributes Strip (Party size + Offer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 15, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              '${booking.partySize} Guests Reserved',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        if (booking.appliedOffer != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.percent_rounded, size: 11, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  booking.appliedOffer!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'Standard Reservation',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),

                  // If Confirmed: Status banner & Seat Diner Action
                  if (isConfirmed) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'Confirmed · Ready for service',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Action Button for Confirmed: Seat Diner
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markSeated(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chair_rounded, size: 16),
                        label: const Text(
                          'Seat Diner',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ],

                  // If Marked No-Show: Notification Banner
                  if (isNoShow) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_off_rounded, size: 15, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customer Marked as No-Show · Capacity Released',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // If Completed: Notification Banner
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Guest Arrived & Seated · Bill Paid via UPI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons for Pending Reservations: Decline & Accept
                  if (isPending) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (onDecline != null) {
                                onDecline!();
                              } else {
                                Provider.of<BookingProvider>(context, listen: false)
                                    .updateStatus(booking.bookingId, BookingStatus.rejected);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Decline',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              onAccept?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 16),
                            label: const Text(
                              'Accept Table',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
