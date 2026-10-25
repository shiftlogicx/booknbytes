import 'package:flutter/material.dart';
import '../config/theme.dart';

class OfferBadge extends StatelessWidget {
  final String title;
  final bool isCompact;

  const OfferBadge({
    super.key,
    required this.title,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EB),
        borderRadius: BorderRadius.circular(6),
        border: Border.parse('1px solid #FFD8BE'),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: isCompact ? 10 : 12,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
