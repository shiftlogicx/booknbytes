import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _faqSearchController = TextEditingController();
  String _searchQuery = '';

  final List<_FaqItem> _allFaqs = const [
    _FaqItem(
      question: 'How do Priority Full-Screen Booking Alerts work?',
      answer:
          'When a new table reservation is placed by a diner, your phone receives an immediate high-priority alarm. It displays a full-screen alert overlay with continuous acoustic ringing and vibration until you either Slide to Accept or Snooze.',
      category: 'ALERTS & HARDWARE',
    ),
    _FaqItem(
      question: 'How does instant 0% fee UPI settlement work with guests?',
      answer:
          'Diners pay their bill by scanning the table UPI QR code. The payment is transferred directly from the diner\'s bank to your verified UPI VPA ID (e.g. maheshlunch@sbi) with zero commission or aggregator deduction.',
      category: 'PAYMENTS & SETTLEMENT',
    ),
    _FaqItem(
      question: 'What is the partner policy for guest no-shows?',
      answer:
          'Diners are given a 15-minute grace window past their reserved time slot. If they do not arrive, you can tap \'Mark No-Show\' in the Bookings tab, which immediately frees up table capacity and alerts the customer.',
      category: 'RESERVATIONS & SEATING',
    ),
    _FaqItem(
      question: 'How do I configure dynamic hourly discounts and slot limits?',
      answer:
          'Open the \'Slots\' tab in the bottom navigation dock. You can toggle lunch and dinner time blocks and assign customized discounts (10% to 40% OFF) to boost footfall during off-peak hours.',
      category: 'DISCOUNTS & SLOTS',
    ),
    _FaqItem(
      question: 'How is restaurant dining capacity tracked during rush hours?',
      answer:
          'The Floor dashboard monitors your current active covers against total capacity (e.g. 82% occupied). It computes pending arrivals and predicted rush timelines (8:00 PM, 8:30 PM, 9:00 PM) to help you manage table turnover.',
      category: 'FLOOR MANAGEMENT',
    ),
    _FaqItem(
      question: 'Can I temporarily pause online reservations during a kitchen rush?',
      answer:
          'Yes. At the top of the Floor tab, simply toggle off \'Accepting Reservations\'. All customer apps will temporarily show tables as fully booked until you turn the toggle back on.',
      category: 'RESERVATIONS & SEATING',
    ),
    _FaqItem(
      question: 'How do I update my FSSAI number and business address?',
      answer:
          'Navigate to Settings > Restaurant Profile. You can update your 14-digit FSSAI license, contact phone, operating shifts, and outlet address. Changes take effect immediately upon saving.',
      category: 'MERCHANT COMPLIANCE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _faqSearchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String label, String value) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 18),
            const SizedBox(width: 10),
            Text('$label copied to clipboard: $value'),
          ],
        ),
        backgroundColor: const Color(0xFF101420),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _requestCallback() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E599).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_callback_rounded, color: Color(0xFF00E599), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Callback Requested',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text('Dedicated Partner Success Manager', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Our partner support executive will connect directly to your registered mobile (+91 98200 87654) within 5 to 10 minutes.',
                style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E599),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Acknowledged • Return to App', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedbackDialog() {
    HapticFeedback.lightImpact();
    int selectedRating = 5;
    String selectedCategory = 'App Experience';
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Partner Feedback & Bug Report',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your direct feedback shapes future releases for Book & Bite Partner.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 18),

                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          icon: Icon(
                            starIndex <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 34,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedRating = starIndex);
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                    const Text('FEEDBACK CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'App Experience',
                        'Audio & Alarm Ring',
                        'Table Management',
                        'UPI Settlements',
                        'Feature Request',
                      ].map((cat) {
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: const Color(0xFF00E599).withValues(alpha: 0.2),
                          backgroundColor: const Color(0xFF171E2D),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel ? const Color(0xFF00E599) : const Color(0xFF94A3B8),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text('YOUR MESSAGE / BUG DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),

                    TextField(
                      controller: feedbackController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened or suggest an enhancement...',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF171E2D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF28344E)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF28344E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00E599)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E599),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF00E599)),
                                  SizedBox(width: 10),
                                  Text('Thank you! Your feedback has been sent to our tech team.'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF101420),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: const Text('Submit Partner Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

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
              'Partner Help & Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              '24x7 Merchant Helpdesk, FAQs & Feedback',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E599),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00E599),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'CONTACT US'),
            Tab(text: 'GENERAL FAQS'),
            Tab(text: 'FEEDBACK'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactUsTab(auth),
          _buildFaqsTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildContactUsTab(AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // 24x7 Priority Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF131D30), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222F49)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E599),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PARTNER DESK LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF00E599),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Avg Response: < 2 min',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Direct Merchant Concierge',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Support for ${auth.currentRestaurantName} (${auth.currentRestaurantId})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E599),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone_callback_rounded, size: 18),
                  label: const Text('Request Instant Callback (< 5 mins)', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: _requestCallback,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'INSTANT COMMUNICATION CHANNELS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        // WhatsApp Channel
        _buildSupportTile(
          icon: Icons.chat_rounded,
          iconColor: const Color(0xFF25D366),
          title: 'WhatsApp Merchant Desk',
          subtitle: '+91 98200 12345 · Instant chat support',
          actionLabel: 'Chat / Copy',
          onTap: () => _copyToClipboard('WhatsApp Number', '+91 98200 12345'),
        ),

        // Priority Helpline
        _buildSupportTile(
          icon: Icons.phone_in_talk_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: 'Priority Partner Helpline',
          subtitle: '1800-BOOK-BITE (Toll-Free 24x7)',
          actionLabel: 'Call / Copy',
          onTap: () => _copyToClipboard('Partner Helpline', '1800-2665-2483'),
        ),

        // Email Channel
        _buildSupportTile(
          icon: Icons.email_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Executive Support Email',
          subtitle: 'partner-desk@booknbite.com',
          actionLabel: 'Mail / Copy',
          onTap: () => _copyToClipboard('Support Email', 'partner-desk@booknbite.com'),
        ),

        const SizedBox(height: 24),
        const Text(
          'ACCOUNT MANAGER',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF101420),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222B3D)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF00E599).withValues(alpha: 0.2),
                child: const Text('RS', style: TextStyle(color: Color(0xFF00E599), fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rohan Singhal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Senior Partner Growth Manager · Pune Region', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: Color(0xFF00E599), size: 20),
                onPressed: () => _copyToClipboard('Manager Phone', '+91 99887 66554'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqsTab() {
    final filteredFaqs = _searchQuery.isEmpty
        ? _allFaqs
        : _allFaqs.where((f) =>
            f.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.answer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _faqSearchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search partner questions, alerts, UPI...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E599), size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                      onPressed: () {
                        _faqSearchController.clear();
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
        ),

        // FAQs List
        Expanded(
          child: filteredFaqs.isEmpty
              ? const Center(
                  child: Text('No matching questions found', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, idx) {
                    final item = filteredFaqs[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101420),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF222B3D)),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF00E599),
                          collapsedIconColor: const Color(0xFF94A3B8),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF00E599), letterSpacing: 0.6),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.question,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                          children: [
                            Text(
                              item.answer,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF131726), Color(0xFF0F121C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222B3D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF00E599), size: 32),
              const SizedBox(height: 14),
              const Text(
                'Partner Feedback & Bug Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Notice an issue with the alarm chime, dining slots, or want a new feature? Share your thoughts directly with the product engineering team.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E599),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_comment_rounded, size: 18),
                  label: const Text('Write Feedback or Report Bug', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: _showFeedbackDialog,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'COMMUNITY METRICS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        _buildCommunityTile(
          icon: Icons.speed_rounded,
          title: '99.98% System Uptime',
          subtitle: 'Real-time alert delivery latency < 450ms',
        ),
        _buildCommunityTile(
          icon: Icons.security_rounded,
          title: 'Bank-Grade UPI Settlements',
          subtitle: 'Direct NPCI payment rails, 0% platform intermediary',
        ),
        _buildCommunityTile(
          icon: Icons.update_rounded,
          title: 'Weekly Feature Updates',
          subtitle: 'Partner feedback directly drives weekly app updates',
        ),
      ],
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF171E2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28344E)),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00E599)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101420),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222B3D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E599), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
