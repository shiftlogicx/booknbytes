import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CRED-style tactile Swipe-To-Confirm Slider
class CredSwipeSlider extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final Color baseColor;
  final Color activeColor;
  final IconData icon;

  const CredSwipeSlider({
    super.key,
    this.label = 'SLIDE TO ACCEPT TABLE',
    required this.onConfirmed,
    this.baseColor = const Color(0xFF161C2A),
    this.activeColor = const Color(0xFF00E599), // CRED Neon Emerald
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<CredSwipeSlider> createState() => _CredSwipeSliderState();
}

class _CredSwipeSliderState extends State<CredSwipeSlider>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  late AnimationController _shimmerController;

  static const double _height = 62.0;
  static const double _thumbSize = 52.0;
  static const double _padding = 5.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Gentle micro-haptic tick during slide
    if ((_dragPosition % 28).abs() < 2) {
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;
    if (_dragPosition >= maxDrag * 0.78) {
      // Confirmed!
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    } else {
      // Snap back
      HapticFeedback.lightImpact();
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_padding * 2);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF263044),
                widget.activeColor,
                progress * 0.8,
              )!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.activeColor.withValues(alpha: 0.15 * progress),
                blurRadius: 18 * progress,
                spreadRadius: 2 * progress,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Dynamic Fill Background
              AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: _thumbSize + _dragPosition + _padding,
                height: _height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.activeColor.withValues(alpha: 0.28),
                      widget.activeColor.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
              ),

              // Center Shimmering Text
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.4)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (0.3 + (_shimmerController.value * 0.7)),
                            child: const Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              size: 18,
                              color: Color(0xFF00E599),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Draggable Thumb Pill
              Positioned(
                left: _padding + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.activeColor,
                          Color.lerp(widget.activeColor, Colors.white, 0.25)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check_rounded : widget.icon,
                      color: const Color(0xFF070B14),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
