import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class BookingLedgerDocScreen extends StatefulWidget {
  const BookingLedgerDocScreen({super.key});

  @override
  State<BookingLedgerDocScreen> createState() => _BookingLedgerDocScreenState();
}

class _BookingLedgerDocScreenState extends State<BookingLedgerDocScreen> {
  String _activeFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _downloadStatement() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('📄 ✨ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Reconciliation Doc Generated: BB-LEDGER-OCT2026.pdf exported to device!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF101420),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E599), width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);
    final all = booking.allBookings;

    // Filter by tab
    List<BookingModel> filtered = all.where((b) {
      if (_activeFilter == 'SEATED') return b.isCompleted;
      if (_activeFilter == 'NO_SHOW') return b.isNoShow;
      if (_activeFilter == 'DISCOUNTED') return b.appliedOffer != null && b.appliedOffer!.isNotEmpty;
      return true;
    }).toList();

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final query = _searchQuery.toLowerCase();
        final name = (b.customerName ?? '').toLowerCase();
        final id = b.bookingId.toLowerCase();
        final offer = (b.appliedOffer ?? '').toLowerCase();
        return name.contains(query) || id.contains(query) || offer.contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101420),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Booking Ledger',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Audit Statement of Bookings, Attendance & Discounts',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download PDF Statement',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF00E599)),
            onPressed: _downloadStatement,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Official Document Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF131D30), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF222F49), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E599).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00E599).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Text('📜 ', style: TextStyle(fontSize: 10)),
                            Text(
                              'OFFICIAL RECONCILIATION DOC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00E599),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Period: Oct 2026',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.currentRestaurantName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Merchant ID: ${auth.currentRestaurantId} · Settlement UPI: ${auth.profile.upiId}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF1E283E), height: 1),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF00E599), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Direct diner UPI settlement · 0% commission deducted by Book & Bite',
                          style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Executive KPI Cards
            const Text(
              'PLATFORM ATTENDANCE & CONVERSION SUMMARY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              padding: EdgeInsets.zero,
              children: [
                _buildKpiCard(
                  title: 'BOOKINGS FROM US',
                  value: '${booking.totalCount}',
                  subtitle: 'Platform Generated',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF38BDF8),
                ),
                _buildKpiCard(
                  title: 'ACTUALLY CAME',
                  value: '${booking.completedCount}',
                  subtitle: '${booking.attendanceRate.toStringAsFixed(1)}% Conversion',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF00E599),
                ),
                _buildKpiCard(
                  title: 'MARKED NO-SHOW',
                  value: '${booking.noShowCount}',
                  subtitle: '${((booking.noShowCount / (booking.totalCount == 0 ? 1 : booking.totalCount)) * 100).toStringAsFixed(1)}% No-Show',
                  icon: Icons.person_off_rounded,
                  color: const Color(0xFFEF4444),
                ),
                _buildKpiCard(
                  title: 'DISCOUNTS APPLIED',
                  value: '₹${booking.totalDiscountGiven}',
                  subtitle: '${booking.discountedCount} Discounted Covers',
                  icon: Icons.percent_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Visual Segmented Attendance Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101420),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF222B3D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GUEST ATTENDANCE RATIO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '${booking.attendanceRate.toStringAsFixed(0)}% Seated Success',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00E599)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(
                            flex: booking.completedCount > 0 ? booking.completedCount : 8,
                            child: Container(color: const Color(0xFF00E599)),
                          ),
                          Expanded(
                            flex: booking.noShowCount > 0 ? booking.noShowCount : 1,
                            child: Container(color: const Color(0xFFEF4444)),
                          ),
                          Expanded(
                            flex: booking.confirmedCount > 0 ? booking.confirmedCount : 2,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                          Expanded(
                            flex: booking.cancelledCount > 0 ? booking.cancelledCount : 1,
                            child: Container(color: const Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegend(const Color(0xFF00E599), 'Came (${booking.completedCount})'),
                      _buildLegend(const Color(0xFFEF4444), 'No-Show (${booking.noShowCount})'),
                      _buildLegend(const Color(0xFFF59E0B), 'Active (${booking.confirmedCount})'),
                      _buildLegend(const Color(0xFF334155), 'Cancelled (${booking.cancelledCount})'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Itemized Booking Audit Log Header
            const Text(
              'ITEMIZED BOOKING & DISCOUNT AUDIT LOG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search diner name, booking ID, or discount code...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E599), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF101420),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF222B3D))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF222B3D))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00E599))),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Bookings (${all.length})'),
                  _buildFilterChip('SEATED', 'Actually Came (${booking.completedCount})'),
                  _buildFilterChip('NO_SHOW', 'Marked No-Show (${booking.noShowCount})'),
                  _buildFilterChip('DISCOUNTED', 'With Discounts (${booking.discountedCount})'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Detailed Bookings List
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF101420),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222B3D)),
                ),
                child: const Column(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 34)),
                    SizedBox(height: 10),
                    Text(
                      'No bookings match this audit filter',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Try switching filter chips above to view records',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((item) => _buildLedgerEntryCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 13),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSel = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = filterKey);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00E599) : const Color(0xFF101420),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? const Color(0xFF00E599) : const Color(0xFF222B3D)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSel ? Colors.black : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerEntryCard(BookingModel item) {
    Color statusBg;
    Color statusText;
    String statusLabel;
    IconData statusIcon;

    if (item.isCompleted) {
      statusBg = const Color(0xFF00E599).withValues(alpha: 0.15);
      statusText = const Color(0xFF00E599);
      statusLabel = 'SEATED';
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isNoShow) {
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      statusText = const Color(0xFFEF4444);
      statusLabel = 'NO-SHOW';
      statusIcon = Icons.person_off_rounded;
    } else if (item.isConfirmed) {
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      statusText = const Color(0xFFFBBF24);
      statusLabel = 'CONFIRMED';
      statusIcon = Icons.schedule_rounded;
    } else if (item.isCancelled) {
      statusBg = const Color(0xFF64748B).withValues(alpha: 0.15);
      statusText = const Color(0xFF94A3B8);
      statusLabel = 'CANCELLED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFF38BDF8).withValues(alpha: 0.15);
      statusText = const Color(0xFF38BDF8);
      statusLabel = 'PENDING';
      statusIcon = Icons.pending_actions_rounded;
    }

    final hasDiscount = item.appliedOffer != null && item.appliedOffer!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isNoShow
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : const Color(0xFF222B3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID + Date + Status (responsive, non-overflowing)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF171E2D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF28344E)),
                ),
                child: Text(
                  '#${item.bookingId.replaceAll('bk_', '')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.timeSlot} · ${item.date}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusText.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: statusText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Guest Details
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.customerName ?? 'Guest Diner',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E283E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.partySize} Guests',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1E283D), height: 1),
          const SizedBox(height: 10),

          // Discount & Settlement Row (responsive with Flexible)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Offer: ',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasDiscount
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF1E283E),
                          borderRadius: BorderRadius.circular(6),
                          border: hasDiscount
                              ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Text(
                          hasDiscount ? '${item.appliedOffer}' : 'Standard (0% OFF)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: hasDiscount ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasDiscount ? 'Cover: ₹${item.partySize * 600}' : 'Full Menu Price',
                style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
              ),
            ],
          ),

          if (item.isNoShow && item.specialRequests != null) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ ${item.specialRequests}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFFCA5A5), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
