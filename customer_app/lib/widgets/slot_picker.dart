import 'package:flutter/material.dart';
import '../config/theme.dart';

class SlotPicker extends StatelessWidget {
  final Map<String, int> slots; // e.g., {"19:00": 5, "19:30": 3, "20:00": 0}
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  const SlotPicker({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'No slots available for this date',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final sortedEntries = slots.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Time Slots',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedEntries.map((entry) {
            final slot = entry.key;
            final count = entry.value;
            final isAvailable = count > 0;
            final isSelected = slot == selectedSlot;

            return GestureDetector(
              onTap: isAvailable ? () => onSelected(slot) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : isAvailable
                          ? Colors.white
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : isAvailable
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slot,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? Colors.grey.shade900
                                : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable ? '$count tables' : 'Full',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : isAvailable
                                ? Colors.green.shade700
                                : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
