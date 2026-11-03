import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupportScreen extends StatefulWidget {
  final int initialTabIndex;
  const SupportScreen({super.key, this.initialTabIndex = 0});

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
          'When a diner places a table reservation, your device receives a high-priority alert. A full-screen overlay displays reservation details with acoustic ringing and vibration so your team never misses an incoming booking. You can slide or tap to confirm or snooze.',
      category: 'ALERTS & HARDWARE',
    ),
    _FaqItem(
      question: 'What is the restaurant policy for guest no-shows?',
      answer:
          'Diners are given a 15-minute grace window past their reserved time slot. If guests do not arrive within this window, their table reservation automatically expires so walk-in diners can be accommodated.',
      category: 'RESERVATIONS & SEATING',
    ),
    _FaqItem(
      question: 'How do I set up Breakfast, Lunch, and Dinner service shifts?',
      answer:
          'Navigate to Settings > Restaurant Profile > Operational Service Shifts. You can customize the opening and closing hours for Breakfast, Lunch, and Dinner. These shifts define when diners can book tables on customer apps.',
      category: 'SERVICE SHIFTS',
    ),
    _FaqItem(
      question: 'How do I configure Dynamic Min-Max discounts?',
      answer:
          'Open the Slots tab in the bottom navigation. Toggle "Enable Dynamic Min-Max Discount" and choose a strategy preset or fine-tune your Floor (Min) and Ceiling (Max) limits. Diners roll a dynamic surprise discount within your limits when reserving a table.',
      category: 'DISCOUNTS & SLOTS',
    ),
    _FaqItem(
      question: 'How is restaurant dining capacity tracked on the Floor?',
      answer:
          'The Floor dashboard monitors your live seated covers and upcoming reservations for today. You can mark guests as seated when they arrive to track live occupancy and turn tables efficiently.',
      category: 'FLOOR MANAGEMENT',
    ),
    _FaqItem(
      question: 'Can I temporarily pause online reservations during a kitchen rush?',
      answer:
          'Yes. At the top of the Floor tab, tap the LIVE toggle. Switching it to PAUSED temporarily stops incoming table reservations until you switch it back on.',
      category: 'RESERVATIONS & SEATING',
    ),
    _FaqItem(
      question: 'How do I update my FSSAI license, contact phone, and outlet address?',
      answer:
          'Navigate to Settings > Restaurant Profile. You can update your 14-digit FSSAI license, contact phone number, operating shifts, and outlet address. Changes save directly to your profile.',
      category: 'RESTAURANT PROFILE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _faqSearchController.dispose();
    super.dispose();
  }

  void _showFeedbackDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'General Suggestion';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Share Feedback or Report an Issue',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'General Suggestion', child: Text('General Suggestion')),
                  DropdownMenuItem(value: 'Alert / Sound Issue', child: Text('Alert / Sound Issue')),
                  DropdownMenuItem(value: 'Slot / Timings Bug', child: Text('Slot / Timings Bug')),
                  DropdownMenuItem(value: 'Floor / Attendance Request', child: Text('Floor / Attendance Request')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Details',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your observation or feature request...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thank you! Your feedback has been submitted to the product team.',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Restaurant FAQs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Guides for alerts, shifts, slots & floor operations',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 3,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'FAQS'),
                Tab(text: 'FEEDBACK'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqsTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  Widget _buildFaqsTab() {
    final filteredFaqs = _searchQuery.isEmpty
        ? _allFaqs
        : _allFaqs.where((f) =>
            f.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Search Box
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _faqSearchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search operational guides & FAQs...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _faqSearchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // List of FAQs
        Expanded(
          child: filteredFaqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text(
                        'No questions found matching "$_searchQuery"',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, idx) {
                    final item = filteredFaqs[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          iconColor: const Color(0xFF059669),
                          collapsedIconColor: const Color(0xFF94A3B8),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.question,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          children: [
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),
                            Text(
                              item.answer,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.45,
                              ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF059669), size: 32),
              const SizedBox(height: 14),
              const Text(
                'Restaurant Feedback & Bug Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Notice an issue with booking alarms, dining slots, or want a new feature? Share your thoughts directly with the product engineering team.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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
          'PLATFORM METRICS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        _buildMetricTile(
          icon: Icons.speed_rounded,
          title: '99.98% System Uptime',
          subtitle: 'Real-time alert delivery latency < 450ms',
        ),
        _buildMetricTile(
          icon: Icons.verified_user_rounded,
          title: 'Direct Reservation Sync',
          subtitle: 'Instant diner-to-restaurant notification pipeline',
        ),
        _buildMetricTile(
          icon: Icons.update_rounded,
          title: 'Continuous Feature Improvements',
          subtitle: 'Restaurant feedback directly shapes weekly updates',
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
