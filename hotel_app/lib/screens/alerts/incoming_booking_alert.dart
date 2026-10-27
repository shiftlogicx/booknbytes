import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';

class IncomingBookingAlertScreen extends StatefulWidget {
  final BookingModel booking;

  const IncomingBookingAlertScreen({
    super.key,
    required this.booking,
  });

  @override
  State<IncomingBookingAlertScreen> createState() => _IncomingBookingAlertScreenState();
}

class _IncomingBookingAlertScreenState extends State<IncomingBookingAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onAccept() async {
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    await bookingProvider.updateStatus(widget.booking.bookingId, BookingStatus.confirmed);
    notifProvider.acceptBooking();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Table Confirmed for ${widget.booking.customerName ?? 'Guest'} (${widget.booking.partySize} guests)'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onSnooze() {
    HapticFeedback.mediumImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    notifProvider.snoozeAlert();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⏰ Alert snoozed for 2 minutes'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onReject() async {
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    await bookingProvider.updateStatus(widget.booking.bookingId, BookingStatus.cancelled);
    notifProvider.dismissAlert();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation #${widget.booking.bookingId} Declined'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDinner = widget.booking.timeSlot.compareTo('17:00') >= 0;

    return WillPopScope(
      onWillPop: () async => false, // Require explicit accept/snooze/decline
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                Color(0xFF7F1D1D), // Rich crimson ambient core
                Color(0xFF1E101D),
                Color(0xFF070B14),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Pill
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up_rounded, color: Color(0xFFF87171), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'PRIORITY TABLE ALARM',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Incoming Reservation',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Swiggy Dineout Instant Alert',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),

                  // Center Animated Cloche & Glass Card
                  Column(
                    children: [
                      // Pulsing radar rings
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _ringAnimation,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withOpacity(0.6),
                                    blurRadius: 36,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // High-end Reservation Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B2E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF2A3752)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Diner Name & Party Size
                            Text(
                              widget.booking.customerName ?? 'Guest Diner',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                              ),
                              child: Text(
                                '${widget.booking.partySize} Guests · ${isDinner ? 'Dinner' : 'Lunch'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                            ),

                            const Divider(height: 28, color: Color(0xFF222F49)),

                            // Date & Time Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(Icons.access_time_filled_rounded, 'TIME SLOT', widget.booking.timeSlot),
                                Container(width: 1, height: 32, color: const Color(0xFF222F49)),
                                _buildDetailItem(Icons.calendar_month_rounded, 'DATE', widget.booking.date),
                              ],
                            ),

                            if (widget.booking.appliedOffer != null &&
                                widget.booking.appliedOffer!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF34D399)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Offer: ${widget.booking.appliedOffer!.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34D399),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Action Buttons
                  Column(
                    children: [
                      // Accept Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _onAccept,
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            'ACCEPT TABLE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            elevation: 8,
                            shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Snooze Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _onSnooze,
                              icon: const Icon(Icons.snooze_rounded, color: Color(0xFFFBBF24), size: 18),
                              label: const Text(
                                'Snooze (2m)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Decline Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _onReject,
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                              label: const Text(
                                'Decline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
