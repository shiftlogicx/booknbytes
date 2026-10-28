import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/restaurant_walkthrough_modal.dart';
import '../profile/restaurant_profile_screen.dart';
import '../profile/booking_ledger_doc_screen.dart';
import '../support/support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Alert & Hardware Toggles
  bool _fullScreenAlerts = true;
  bool _loudChimeMode = true;
  bool _hapticRinging = true;

  // Automation & Communication
  bool _instantSmsDiner = true;
  bool _autoAssignTables = true;
  bool _peakHourSurgePricing = true;

  void _showToggleNotice(String name, bool val) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name is now ${val ? "ENABLED ⚡" : "DISABLED"}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _testAudioChime() async {
    HapticFeedback.heavyImpact();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notifProvider.testAlarm();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🔔 ✨ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Playing Priority Dining Bell Acoustic Ringtone...',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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

  void _openProfile() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RestaurantProfileScreen()),
    );
  }

  void _openSupport() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportScreen()),
    );
  }

  void _replayTutorial() {
    HapticFeedback.mediumImpact();
    RestaurantWalkthroughModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Controls & Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Hardware Alerts, Profile & Restaurant Preferences',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Restaurant Luxury Profile Card (Clickable to Edit)
            InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(22),
              child: Container(
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
                  children: [
                    Row(
                      children: [
                        const PremiumBrandLogo(size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Owner: ${profile.ownerName} · ID: ${profile.restaurantId}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 11, color: Color(0xFF059669)),
                                        SizedBox(width: 4),
                                        Text(
                                          'ACTIVE RESTAURANT',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF059669),
                                            letterSpacing: 0.6,
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
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lunch: ${profile.lunchOpen} - ${profile.lunchClose}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dinner: ${profile.dinnerOpen} - ${profile.dinnerClose}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit Details',
                                style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w800),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.edit_rounded, size: 12, color: Color(0xFF059669)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Dining Location Settings
            const Text(
              'OUTLET LOCATION & GPS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                LocationPickerBottomSheet.show(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFBEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active GPS Restaurant Hub',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locationProvider.currentLocation.fullAddress,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Priority Audio & Alert System
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PRIORITY AUDIO & ALERT SYSTEM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton.icon(
                  onPressed: _testAudioChime,
                  icon: const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF059669)),
                  label: const Text(
                    'Test Sound',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            _buildInteractiveToggleTile(
              icon: Icons.notifications_active_rounded,
              title: 'Full-Screen Priority Alerts',
              subtitle: 'Wake screen with ringing priority overlay for new bookings',
              value: _fullScreenAlerts,
              onChanged: (val) {
                setState(() => _fullScreenAlerts = val);
                _showToggleNotice('Full-Screen Priority Alerts', val);
              },
            ),

            _buildInteractiveToggleTile(
              icon: Icons.volume_up_rounded,
              title: 'Loud Notification Chime',
              subtitle: 'High-gain acoustic dining bell chime (plays over silent switch)',
              value: _loudChimeMode,
              onChanged: (val) {
                setState(() => _loudChimeMode = val);
                _showToggleNotice('Loud Notification Chime', val);
              },
            ),

            _buildInteractiveToggleTile(
              icon: Icons.vibration_rounded,
              title: 'Haptic Table Vibration',
              subtitle: 'Tactile synchronous phone pulsing during incoming alarm',
              value: _hapticRinging,
              onChanged: (val) {
                setState(() => _hapticRinging = val);
                _showToggleNotice('Haptic Table Vibration', val);
              },
            ),

            const SizedBox(height: 24),

            // Guest Experience & Automation
            const Text(
              'GUEST EXPERIENCE & AUTOMATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            _buildInteractiveToggleTile(
              icon: Icons.sms_rounded,
              title: 'Instant SMS & WhatsApp to Guest',
              subtitle: 'Automatically dispatch reservation confirmation SMS to diner',
              value: _instantSmsDiner,
              onChanged: (val) {
                setState(() => _instantSmsDiner = val);
                _showToggleNotice('Instant SMS & WhatsApp to Guest', val);
              },
            ),

            _buildInteractiveToggleTile(
              icon: Icons.table_bar_rounded,
              title: 'Auto-Assign Available Table',
              subtitle: 'Pre-allocate next ready table upon acceptance',
              value: _autoAssignTables,
              onChanged: (val) {
                setState(() => _autoAssignTables = val);
                _showToggleNotice('Auto-Assign Table', val);
              },
            ),

            _buildInteractiveToggleTile(
              icon: Icons.trending_up_rounded,
              title: 'Dynamic Surge & Slot Boost',
              subtitle: 'Allow differential discounts to drive footfall during off-peak hours',
              value: _peakHourSurgePricing,
              onChanged: (val) {
                setState(() => _peakHourSurgePricing = val);
                _showToggleNotice('Dynamic Surge & Slot Boost', val);
              },
            ),

            const SizedBox(height: 24),

            // Merchant & Settlement (Editable via Profile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MERCHANT & SETTLEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton(
                  onPressed: _openProfile,
                  child: const Text(
                    'Edit Details',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            _buildActionTile(
              icon: Icons.account_balance_rounded,
              title: 'Direct UPI Settlement VPA',
              subtitle: '${profile.upiId} · 0% fee diner UPI settlement',
              onTap: _openProfile,
            ),
            _buildActionTile(
              icon: Icons.verified_user_rounded,
              title: 'FSSAI License Number',
              subtitle: '${profile.fssaiNumber} · Verified & Compliant',
              onTap: _openProfile,
            ),
            _buildActionTile(
              icon: Icons.receipt_long_rounded,
              title: 'Booking Audit Ledger & Doc',
              subtitle: 'Statement of platform arrivals, no-shows & discounts applied',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookingLedgerDocScreen()),
                );
              },
              accentColor: const Color(0xFF2563EB),
            ),
            _buildActionTile(
              icon: Icons.currency_rupee_rounded,
              title: 'Cost for Two Diners',
              subtitle: '₹${profile.costForTwo} for two · ${profile.cuisines.join(", ")}',
              onTap: _openProfile,
            ),

            const SizedBox(height: 24),

            // Help, Support & FAQs Section
            const Text(
              'HELP, SUPPORT & COMMUNITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.headset_mic_rounded,
              title: '24x7 Restaurant Concierge & Helpline',
              subtitle: 'Instant WhatsApp desk, priority hotline & callback',
              onTap: _openSupport,
              accentColor: const Color(0xFF059669),
            ),
            _buildActionTile(
              icon: Icons.quiz_rounded,
              title: 'General Restaurant FAQs',
              subtitle: 'Answers for alerts, no-show rules, UPI & rush hours',
              onTap: _openSupport,
              accentColor: const Color(0xFF2563EB),
            ),
            _buildActionTile(
              icon: Icons.feedback_rounded,
              title: 'Send Feedback & Bug Reports',
              subtitle: 'Share comments directly with the engineering team',
              onTap: _openSupport,
              accentColor: const Color(0xFFD97706),
            ),

            const SizedBox(height: 24),

            // Onboarding & Tutorial
            const Text(
              'RESTAURANT WALKTHROUGH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.play_lesson_rounded,
              title: 'Replay App Walkthrough Tutorial',
              subtitle: 'Explore priority alarms, 1-touch swipe and dynamic slots',
              onTap: _replayTutorial,
              accentColor: const Color(0xFF4F46E5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (value ? const Color(0xFF059669) : const Color(0xFF64748B)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF059669) : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              activeColor: const Color(0xFF059669),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accentColor = const Color(0xFFD97706),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }
}
