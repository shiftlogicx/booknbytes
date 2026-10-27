import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PartnerWalkthroughModal extends StatefulWidget {
  const PartnerWalkthroughModal({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Walkthrough',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const PartnerWalkthroughModal();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PartnerWalkthroughModal> createState() => _PartnerWalkthroughModalState();
}

class _PartnerWalkthroughModalState extends State<PartnerWalkthroughModal>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _pulseController;

  final List<_WalkthroughSlide> _slides = const [
    _WalkthroughSlide(
      badge: 'FEATURE 01 · PRIORITY ALARMS',
      title: 'Full-Screen Priority Booking Ring',
      subtitle:
          'Never miss a diner during peak rushes. The app wakes your screen with a loud acoustic chime and pulsing alarm until accepted or snoozed.',
      icon: Icons.notifications_active_rounded,
      accentColor: Color(0xFFEF4444),
      visualType: _VisualType.alarmRing,
    ),
    _WalkthroughSlide(
      badge: 'FEATURE 02 · 1-TOUCH CONFIRMATION',
      title: 'CRED Slide to Confirm',
      subtitle:
          'Confirm reservations frictionlessly with an intuitive swipe gesture. Instantly locks covers, allocates tables, and dispatches diner WhatsApp confirmations.',
      icon: Icons.swipe_right_alt_rounded,
      accentColor: Color(0xFF00E599),
      visualType: _VisualType.swipeSlider,
    ),
    _WalkthroughSlide(
      badge: 'FEATURE 03 · OCCUPANCY BOOSTER',
      title: 'Dynamic Time-Slot Discounts',
      subtitle:
          'Max out your tables during off-peak hours. Effortlessly configure hourly discounts (10% to 40% OFF) and set maximum slot caps per hour.',
      icon: Icons.percent_rounded,
      accentColor: Color(0xFFF59E0B),
      visualType: _VisualType.slotDiscounts,
    ),
    _WalkthroughSlide(
      badge: 'FEATURE 04 · LIVE CAPACITY',
      title: 'Floor Covers & Rush Timeline',
      subtitle:
          'Real-time dining floor intelligence. Monitor occupied seats, upcoming 30-min rush peaks, or pause incoming reservations with 1 tap.',
      icon: Icons.analytics_rounded,
      accentColor: Color(0xFF38BDF8),
      visualType: _VisualType.capacityFloor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onFinish() {
    HapticFeedback.mediumImpact();
    Provider.of<AuthProvider>(context, listen: false).markTutorialSeen();
    Navigator.of(context).pop();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1422).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: slide.accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: slide.accentColor.withValues(alpha: 0.12),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar with Skip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: slide.accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            slide.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: slide.accentColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _onFinish,
                          child: const Text(
                            'Skip Tutorial',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Slides PageView
                    SizedBox(
                      height: 340,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (idx) {
                          HapticFeedback.selectionClick();
                          setState(() => _currentPage = idx);
                        },
                        itemBuilder: (context, idx) {
                          final currentSlide = _slides[idx];
                          return _buildSlideContent(currentSlide);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (idx) {
                        final isSelected = _currentPage == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? slide.accentColor
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: slide.accentColor,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _nextPage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Got It • Enter Partner Suite'
                                  : 'Next Feature',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _slides.length - 1
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(_WalkthroughSlide currentSlide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Graphic Box
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: currentSlide.accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: currentSlide.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: _buildVisualGraphic(currentSlide),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          currentSlide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            currentSlide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualGraphic(_WalkthroughSlide currentSlide) {
    switch (currentSlide.visualType) {
      case _VisualType.alarmRing:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.15),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 58,
                color: Color(0xFFEF4444),
              ),
            );
          },
        );
      case _VisualType.swipeSlider:
        return const Icon(
          Icons.swipe_right_alt_rounded,
          size: 64,
          color: Color(0xFF00E599),
        );
      case _VisualType.slotDiscounts:
        return const Icon(
          Icons.percent_rounded,
          size: 58,
          color: Color(0xFFF59E0B),
        );
      case _VisualType.capacityFloor:
        return const Icon(
          Icons.pie_chart_rounded,
          size: 58,
          color: Color(0xFF38BDF8),
        );
    }
  }
}

enum _VisualType { alarmRing, swipeSlider, slotDiscounts, capacityFloor }

class _WalkthroughSlide {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final _VisualType visualType;

  const _WalkthroughSlide({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.visualType,
  });
}
