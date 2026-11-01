import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/cred_swipe_slider.dart';
import '../../widgets/emoji_burst_animation.dart';

/// Full-screen priority incoming booking alert with celebration on confirmation
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  late AnimationController _doneController;
  late Animation<double> _checkScaleAnimation;

  Timer? _countdownTimer;
  int _secondsRemaining = 60;

  bool _isConfirmed = false;
  final String _assignedTable = 'Table T-04';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _doneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _doneController,
      curve: Curves.elasticOut,
    );

    // Auto-countdown for 60 seconds: if unanswered, automatically moves to Pending section
    _secondsRemaining = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _onAutoExpireToPending();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _doneController.dispose();
    super.dispose();
  }

  void _onAccept() {
    _countdownTimer?.cancel();
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    // 1. Immediately stop ringer audio & vibrations
    notifProvider.acceptBooking();

    // 2. Update local and remote booking status to confirmed
    bookingProvider.updateStatus(widget.booking.bookingId, BookingStatus.confirmed);

    // 3. Transition to celebration view
    setState(() {
      _isConfirmed = true;
    });
    _doneController.forward();
    HapticFeedback.heavyImpact();
  }

  void _onAutoExpireToPending() {
    if (_isConfirmed || !mounted) return;
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Stop ringing
    notifProvider.dismissAlert();

    // The booking remains in PENDING status in database and shows in the Pending bookings tab
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFBBF24), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reservation #${widget.booking.bookingId} moved to Pending queue',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isConfirmed,
      onPopInvoked: (didPop) {
        if (!didPop && !_isConfirmed) {
          // Alert requires user action
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isConfirmed ? _buildCelebrationView() : _buildIncomingAlertView(),
        ),
      ),
    );
  }

  /// Incoming Booking Ringing View
  Widget _buildIncomingAlertView() {
    final isDinner = widget.booking.timeSlot.compareTo('17:00') >= 0;

    return Container(
      key: const ValueKey('ringing_view'),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF7F1D1D), // Crimson core
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
              // Top Pill Header
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, color: Color(0xFFF87171), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'RINGING · AUTO-PENDING IN ${_secondsRemaining}S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
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
                    'BookNBytes Instant Table Alert',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),

              // Center Animated Radar & Glass Card
              Column(
                children: [
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
                            widget.booking.appliedOffer != null
                                ? '✨ Offer: ${widget.booking.appliedOffer}'
                                : '⭐ VIP Guest Reservation',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFF222F49)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem(
                              Icons.people_alt_rounded,
                              'PARTY SIZE',
                              '${widget.booking.partySize} Guests',
                            ),
                            Container(width: 1, height: 38, color: const Color(0xFF222F49)),
                            _buildDetailItem(
                              Icons.access_time_filled_rounded,
                              'TIME SLOT',
                              widget.booking.timeSlot,
                            ),
                            Container(width: 1, height: 38, color: const Color(0xFF222F49)),
                            _buildDetailItem(
                              Icons.restaurant_rounded,
                              'MEAL',
                              isDinner ? 'Dinner' : 'Lunch',
                            ),
                          ],
                        ),
                        if (widget.booking.customerPhone != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                widget.booking.customerPhone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
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

              // Bottom Action Buttons: Only Accept Option (Auto-Pending after countdown)
              Column(
                children: [
                  // Prominent Direct Accept Button
                  ElevatedButton(
                    onPressed: _onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E599),
                      foregroundColor: const Color(0xFF070B14),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF00E599).withValues(alpha: 0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 24, color: Color(0xFF070B14)),
                        SizedBox(width: 10),
                        Text(
                          'ACCEPT RESERVATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CRED-Style Alternative Slider
                  CredSwipeSlider(
                    label: 'SLIDE TO CONFIRM TABLE',
                    activeColor: const Color(0xFF00E599),
                    onConfirmed: _onAccept,
                  ),
                  const SizedBox(height: 12),

                  // Live Auto-Pending Countdown Notice (No Reject/Decline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFBBF24), size: 15),
                        const SizedBox(width: 8),
                        Text(
                          'Auto-moves to Pending section in ${_secondsRemaining}s',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Animated Celebration View
  Widget _buildCelebrationView() {
    return Container(
      key: const ValueKey('celebration_view'),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF064E3B), // Deep emerald glow
            Color(0xFF062D24),
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
              const SizedBox(height: 10),

              // Animated Checkmark, Emoji Burst and Title
              Column(
                children: [
                  ScaleTransition(
                    scale: _checkScaleAnimation,
                    child: const EmojiCelebrationBurst(
                      emojis: ['🥳', '🎉', '🍽️', '✨', '👨‍🍳', '🥂', '🔥'],
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reservation Confirmed!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎉 ', style: TextStyle(fontSize: 14)),
                      Text(
                        'Diner is notified',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF00E599),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(' ✨', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),

              // Confirmed Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking.customerName ?? 'Guest Diner',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.booking.customerPhone ?? 'Verified Guest',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                          ),
                          child: Text(
                            _assignedTable,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFF222F49)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          Icons.people_alt_rounded,
                          'GUESTS',
                          '${widget.booking.partySize} People',
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFF222F49)),
                        _buildDetailItem(
                          Icons.access_time_filled_rounded,
                          'TIME',
                          widget.booking.timeSlot,
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFF222F49)),
                        _buildDetailItem(
                          Icons.table_restaurant_rounded,
                          'STATUS',
                          'CONFIRMED',
                        ),
                      ],
                    ),
                    if (widget.booking.appliedOffer != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              'Offer Applied: ${widget.booking.appliedOffer}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Done Return to Floor Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
                  label: const Text(
                    'DONE • READY FOR SERVICE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
