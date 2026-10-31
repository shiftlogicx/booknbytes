import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';
import 'emoji_burst_animation.dart';

class ReservationSuccessDialog extends StatefulWidget {
  final BookingModel booking;
  final String assignedTable;

  const ReservationSuccessDialog({
    super.key,
    required this.booking,
    this.assignedTable = 'Table T-04',
  });

  static Future<void> show(BuildContext context, BookingModel booking) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReservationSuccessDialog(booking: booking),
    );
  }

  @override
  State<ReservationSuccessDialog> createState() => _ReservationSuccessDialogState();
}

class _ReservationSuccessDialogState extends State<ReservationSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    );

    _controller.forward();
    HapticFeedback.heavyImpact();
    NotificationService().playAcceptChime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFF101726),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Happy Emoji Burst Animation
              ScaleTransition(
                scale: _checkScaleAnimation,
                child: const EmojiCelebrationBurst(
                  emojis: ['🥳', '🎉', '🍽️', '✨', '👨‍🍳', '🥂', '🔥'],
                  size: 45,
                ),
              ),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Reservation Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),

              // Italic "Diner is notified"
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 13)),
                  Text(
                    'Diner is notified',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00E599),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(' ✨', style: TextStyle(fontSize: 13)),
                ],
              ),

              const SizedBox(height: 20),

              // Reservation Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151E32),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF222F49)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.booking.customerName ?? 'Verified Diner',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.assignedTable,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF222F49), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          Icons.groups_rounded,
                          '${widget.booking.partySize} Guests',
                          const Color(0xFF38BDF8),
                        ),
                        _buildInfoColumn(
                          Icons.access_time_rounded,
                          widget.booking.timeSlot,
                          const Color(0xFFF59E0B),
                        ),
                        _buildInfoColumn(
                          Icons.percent_rounded,
                          widget.booking.appliedOffer ?? 'STANDARD',
                          const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🍽️ ', style: TextStyle(fontSize: 14)),
                      Text(
                        'Ready for Service',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
