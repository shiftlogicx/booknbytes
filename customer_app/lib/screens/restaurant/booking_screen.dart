import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/restaurant_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/party_size_selector.dart';
import '../../widgets/slot_picker.dart';
import '../bookings/my_bookings_screen.dart';

class BookingScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const BookingScreen({super.key});

  // Constructor with restaurant argument
  const BookingScreen.withRestaurant({super.key, required this.restaurant});

  factory BookingScreen({Key? key, required RestaurantModel restaurant}) {
    return BookingScreen.withRestaurant(key: key, restaurant: restaurant);
  }

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  int _partySize = 2;
  RestaurantOffer? _selectedOffer;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    if (widget.restaurant.activeOffers.isNotEmpty) {
      _selectedOffer = widget.restaurant.activeOffers.first;
    }
  }

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, int> _getSlotsForDate(DateTime date) {
    final key = _formatDateKey(date);
    if (widget.restaurant.dailySlots.containsKey(key)) {
      return widget.restaurant.dailySlots[key]!;
    }
    // Fallback default slots for demo if date doesn't exist yet
    return {
      "19:00": 6,
      "19:30": 4,
      "20:00": 2,
      "20:30": 5,
      "21:00": 3,
    };
  }

  void _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a dining time slot')),
      );
      return;
    }

    setState(() => _isBooking = true);

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userId = authProvider.currentUser?.userId ?? 'usr_demo_${DateTime.now().millisecondsSinceEpoch}';

    final success = await bookingProvider.createBooking(
      userId: userId,
      restaurant: widget.restaurant,
      partySize: _partySize,
      date: _formatDateKey(_selectedDate),
      timeSlot: _selectedSlot!,
      offer: _selectedOffer,
    );

    setState(() => _isBooking = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Booking failed. Please try another slot.'),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Table Reserved!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Your table for $_partySize guests at ${widget.restaurant.name} on ${_formatDateKey(_selectedDate)} at $_selectedSlot is confirmed.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '🔔 High-priority alert dispatched to hotel terminal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots = _getSlotsForDate(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.restaurant.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Size
              PartySizeSelector(
                selectedSize: _partySize,
                onSelected: (size) => setState(() => _partySize = size),
              ),
              const Divider(height: 32),

              // Date Picker Horizontal
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, idx) {
                    final date = DateTime.now().add(Duration(days: idx));
                    final isSelected = _formatDateKey(date) == _formatDateKey(_selectedDate);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              idx == 0 ? 'Today' : DateFormat('EEE').format(date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMM').format(date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),

              // Time Slots Grid
              SlotPicker(
                slots: availableSlots,
                selectedSlot: _selectedSlot,
                onSelected: (slot) => setState(() => _selectedSlot = slot),
              ),
              const Divider(height: 32),

              // Offers applied
              if (widget.restaurant.activeOffers.isNotEmpty) ...[
                const Text(
                  'Apply Dining Offer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.restaurant.activeOffers.map((offer) {
                    final isSelected = _selectedOffer?.offerId == offer.offerId;
                    return ChoiceChip(
                      label: Text(offer.title),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFEDD5),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade700,
                      ),
                      onSelected: (sel) {
                        setState(() {
                          _selectedOffer = sel ? offer : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLATFORM CHARGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const Text('₹0 Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isBooking ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm Table Booking',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
