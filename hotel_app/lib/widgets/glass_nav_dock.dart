import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const GlassNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DockTab(icon: Icons.dashboard_rounded, activeIcon: Icons.dashboard_rounded, label: 'Floor'),
      _DockTab(icon: Icons.calendar_month_rounded, activeIcon: Icons.calendar_month_rounded, label: 'Bookings', badgeCount: 3),
      _DockTab(icon: Icons.percent_rounded, activeIcon: Icons.percent_rounded, label: 'Slots'),
      _DockTab(icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1420).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: const Color(0xFF28344E).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF00E599).withValues(alpha: 0.05),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (idx) {
                final tab = tabs[idx];
                final isSelected = currentIndex == idx;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabSelected(idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E283E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                size: 22,
                                color: isSelected
                                    ? const Color(0xFF00E599) // CRED neon emerald
                                    : const Color(0xFF64748B),
                              ),
                              if (tab.badgeCount != null)
                                Positioned(
                                  top: -4,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF0F1420), width: 1.5),
                                    ),
                                    child: Text(
                                      '${tab.badgeCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  _DockTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}
