import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';

class BookingAuditDocScreen extends StatefulWidget {
  const BookingAuditDocScreen({super.key});

  @override
  State<BookingAuditDocScreen> createState() => _BookingAuditDocScreenState();
}

class _BookingAuditDocScreenState extends State<BookingAuditDocScreen> {
  String _activeFilter = 'ALL'; // ALL, COMPLETED, NO_SHOW, DISCOUNTED
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _downloadStatement() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('📄 ✨ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Audit Document & Reconciliation PDF generated and saved to device storage!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    // Apply Filter & Search to Bookings
    final allBookings = booking.bookings;
    final filteredBookings = allBookings.where((b) {
      if (_activeFilter == 'COMPLETED' && !b.isCompleted) return false;
      if (_activeFilter == 'NO_SHOW' && !b.isNoShow) return false;
      if (_activeFilter == 'DISCOUNTED' && (b.appliedOffer == null || b.appliedOffer!.isEmpty)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = (b.customerName ?? '').toLowerCase().contains(q);
        final idMatch = b.bookingId.toLowerCase().contains(q);
        final offerMatch = (b.appliedOffer ?? '').toLowerCase().contains(q);
        if (!nameMatch && !idMatch && !offerMatch) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Audit Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Audit Statement of Bookings, Attendance & Discounts',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download PDF Statement',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF059669)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Text('📜 ', style: TextStyle(fontSize: 10)),
                            Text(
                              'OFFICIAL RECONCILIATION DOC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Period: Oct 2026',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.currentRestaurantName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Merchant ID: ${auth.currentRestaurantId} · Settlement UPI: ${auth.profile.upiId}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Direct diner UPI settlement · 0% commission deducted by BookNBytes',
                          style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
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
                  color: const Color(0xFF2563EB),
                ),
                _buildKpiCard(
                  title: 'ACTUALLY CAME',
                  value: '${booking.completedCount}',
                  subtitle: '${booking.attendanceRate.toStringAsFixed(1)}% Conversion',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                ),
                _buildKpiCard(
                  title: 'MARKED NO-SHOW',
                  value: '${booking.noShowCount}',
                  subtitle: '${((booking.noShowCount / (booking.totalCount == 0 ? 1 : booking.totalCount)) * 100).toStringAsFixed(1)}% No-Show',
                  icon: Icons.person_off_rounded,
                  color: const Color(0xFFDC2626),
                ),
                _buildKpiCard(
                  title: 'DISCOUNTS APPLIED',
                  value: '₹${booking.totalDiscountGiven}',
                  subtitle: '${booking.discountedCount} Discounted Covers',
                  icon: Icons.percent_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Visual Segmented Attendance Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
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
                            child: Container(color: const Color(0xFF059669)),
                          ),
                          Expanded(
                            flex: booking.noShowCount > 0 ? booking.noShowCount : 1,
                            child: Container(color: const Color(0xFFDC2626)),
                          ),
                          Expanded(
                            flex: booking.confirmedCount > 0 ? booking.confirmedCount : 2,
                            child: Container(color: const Color(0xFFD97706)),
                          ),
                          Expanded(
                            flex: booking.cancelledCount > 0 ? booking.cancelledCount : 1,
                            child: Container(color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegend(const Color(0xFF059669), 'Came (${booking.completedCount})'),
                      _buildLegend(const Color(0xFFDC2626), 'No-Show (${booking.noShowCount})'),
                      _buildLegend(const Color(0xFFD97706), 'Active (${booking.confirmedCount})'),
                      _buildLegend(const Color(0xFF94A3B8), 'Cancelled (${booking.cancelledCount})'),
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
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search diner name, booking ID, or discount code...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF059669), size: 18),
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
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF059669))),
              ),
            ),

            const SizedBox(height: 12),

            // Quick Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Bookings (${allBookings.length})'),
                  _buildFilterChip('COMPLETED', 'Came & Seated (${booking.completedCount})'),
                  _buildFilterChip('NO_SHOW', 'Marked No-Show (${booking.noShowCount})'),
                  _buildFilterChip('DISCOUNTED', 'With % Discount (${booking.discountedCount})'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Booking Audit Cards List
            if (filteredBookings.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 10),
                    Text(
                      'No matching bookings found in audit documents',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...filteredBookings.map((b) => _buildAuditEntryCard(b)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: color.withValues(alpha: 0.1),
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
                color: Color(0xFF0F172A),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
          color: isSel ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isSel ? 0.1 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditEntryCard(BookingModel item) {
    Color statusBg;
    Color statusText;
    String statusLabel;
    IconData statusIcon;

    if (item.isCompleted) {
      statusBg = const Color(0xFFECFDF5);
      statusText = const Color(0xFF059669);
      statusLabel = 'SEATED';
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isNoShow) {
      statusBg = const Color(0xFFFEF2F2);
      statusText = const Color(0xFFDC2626);
      statusLabel = 'NO-SHOW';
      statusIcon = Icons.person_off_rounded;
    } else if (item.isConfirmed) {
      statusBg = const Color(0xFFFFFBEB);
      statusText = const Color(0xFFD97706);
      statusLabel = 'CONFIRMED';
      statusIcon = Icons.schedule_rounded;
    } else if (item.isCancelled) {
      statusBg = const Color(0xFFF1F5F9);
      statusText = const Color(0xFF64748B);
      statusLabel = 'CANCELLED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFEFF6FF);
      statusText = const Color(0xFF2563EB);
      statusLabel = 'PENDING';
      statusIcon = Icons.pending_actions_rounded;
    }

    final hasDiscount = item.appliedOffer != null && item.appliedOffer!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isNoShow
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID + Date + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '#${item.bookingId.replaceAll('bk_', '')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.timeSlot} · ${item.date}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
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
                  border: Border.all(color: statusText.withValues(alpha: 0.3)),
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
              const Icon(Icons.person_rounded, size: 16, color: Color(0xFF0F172A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.customerName ?? 'Guest Diner',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${item.partySize} Guests',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 10),

          // Discount & Settlement Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Offer: ',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasDiscount
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: hasDiscount
                              ? Border.all(color: const Color(0xFFFDE68A))
                              : null,
                        ),
                        child: Text(
                          hasDiscount ? '${item.appliedOffer}' : 'Standard (0% OFF)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: hasDiscount ? const Color(0xFFD97706) : const Color(0xFF64748B),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
            ],
          ),

          if (item.isNoShow && item.specialRequests != null) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ ${item.specialRequests}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
