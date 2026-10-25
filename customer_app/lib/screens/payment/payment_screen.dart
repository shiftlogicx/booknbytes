import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/upi_service.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController(text: '1200');
  bool _isLaunching = false;
  String _upiId = 'maheshlunch@sbi'; // Default fallback

  @override
  void initState() {
    super.initState();
    _fetchRestaurantUpi();
  }

  void _fetchRestaurantUpi() {
    final restProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final rest = restProvider.allRestaurants.firstWhere(
      (r) => r.restaurantId == widget.booking.restaurantId,
      orElse: () => restProvider.allRestaurants.isNotEmpty
          ? restProvider.allRestaurants.first
          : null as dynamic,
    );
    if (rest != null && rest.upiId.isNotEmpty) {
      setState(() {
        _upiId = rest.upiId;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initiateDirectUpiPayment() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount')),
      );
      return;
    }

    setState(() => _isLaunching = true);

    final launched = await UpiService.launchUpiPayment(
      upiId: _upiId,
      payeeName: widget.booking.restaurantName,
      amount: amount,
      transactionNote: 'Book & Bite Dining ${widget.booking.bookingId}',
    );

    setState(() => _isLaunching = false);

    if (mounted) {
      if (!launched) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('UPI Intent Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The direct-to-merchant UPI deep link scheme was prepared:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    UpiService.generateUpiLink(
                      upiId: _upiId,
                      payeeName: widget.booking.restaurantName,
                      amount: amount,
                      transactionNote: 'Book & Bite Bill',
                    ),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'On a physical Android/iOS device with GPay, PhonePe, or Paytm installed, this triggers the OS payment sheet with zero platform fees.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Direct Settlement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant Info Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.booking.restaurantName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.emerald.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DIRECT-TO-UPI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Booking ID: ${widget.booking.bookingId} • ${widget.booking.date} at ${widget.booking.timeSlot}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Merchant VPA (UPI ID):',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _upiId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bill Amount input
              const Text(
                'Enter Dining Bill Amount (₹)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 24, color: AppTheme.primaryOrange),
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Zero platform deduction. 100% of payment goes directly to restaurant bank account.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 28),

              // Pay Bill via UPI Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLaunching ? null : _initiateDirectUpiPayment,
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                  label: _isLaunching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Pay via UPI (GPay / PhonePe / Paytm)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Supported UPI apps badges
              Center(
                child: Wrap(
                  spacing: 12,
                  children: [
                    _buildAppPill('Google Pay'),
                    _buildAppPill('PhonePe'),
                    _buildAppPill('Paytm'),
                    _buildAppPill('BHIM UPI'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppPill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
      ),
    );
  }
}
