enum SlotShift {
  lunch,
  dinner,
  lateNight,
}

class SlotDiscountModel {
  final String id;
  final String time; // e.g. "12:00 PM", "12:30 PM", "08:00 PM"
  final SlotShift shift;
  bool isAvailable;
  int capacityTables;
  int bookedTables;
  int discountPercentage; // 0, 10, 15, 20, 25, 30, 40
  String? tag; // "Happy Hour", "Early Bird", "Peak Hour", "Super Deal"

  SlotDiscountModel({
    required this.id,
    required this.time,
    required this.shift,
    this.isAvailable = true,
    this.capacityTables = 8,
    this.bookedTables = 2,
    this.discountPercentage = 0,
    this.tag,
  });

  int get availableTables => (capacityTables - bookedTables).clamp(0, capacityTables);

  SlotDiscountModel copyWith({
    String? id,
    String? time,
    SlotShift shift = SlotShift.lunch,
    bool? isAvailable,
    int? capacityTables,
    int? bookedTables,
    int? discountPercentage,
    String? tag,
  }) {
    return SlotDiscountModel(
      id: id ?? this.id,
      time: time ?? this.time,
      shift: shift,
      isAvailable: isAvailable ?? this.isAvailable,
      capacityTables: capacityTables ?? this.capacityTables,
      bookedTables: bookedTables ?? this.bookedTables,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      tag: tag ?? this.tag,
    );
  }
}
