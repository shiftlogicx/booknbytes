import 'package:intl/intl.dart';

class DailySlotModel {
  final String slotId;
  final String restaurantId;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final double discountPercentage;
  final double? minDiscount;
  final double? maxDiscount;
  final int capacity;

  const DailySlotModel({
    required this.slotId,
    required this.restaurantId,
    this.startDatetime,
    this.endDatetime,
    required this.discountPercentage,
    this.minDiscount,
    this.maxDiscount,
    required this.capacity,
  });

  factory DailySlotModel.fromMap(Map<String, dynamic> map) {
    DateTime? start;
    DateTime? end;
    if (map['start_datetime'] != null) {
      start = DateTime.tryParse(map['start_datetime'].toString())?.toLocal();
    }
    if (map['end_datetime'] != null) {
      end = DateTime.tryParse(map['end_datetime'].toString())?.toLocal();
    }

    final disc = (map['discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final minD = (map['min_discount'] as num?)?.toDouble();
    final maxD = (map['max_discount'] as num?)?.toDouble();

    return DailySlotModel(
      slotId: map['slot_id']?.toString() ?? '',
      restaurantId: map['restaurant_id']?.toString() ?? '',
      startDatetime: start,
      endDatetime: end,
      discountPercentage: disc,
      minDiscount: minD ?? (disc > 0 ? disc : null),
      maxDiscount: maxD ?? (disc > 0 ? disc : null),
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (slotId.isNotEmpty) 'slot_id': slotId,
      'restaurant_id': restaurantId,
      'start_datetime': startDatetime?.toUtc().toIso8601String(),
      'end_datetime': endDatetime?.toUtc().toIso8601String(),
      'discount_percentage': discountPercentage,
      if (minDiscount != null) 'min_discount': minDiscount,
      if (maxDiscount != null) 'max_discount': maxDiscount,
      'capacity': capacity,
    };
  }

  bool get hasMinMaxDiscount =>
      minDiscount != null &&
      maxDiscount != null &&
      minDiscount! > 0 &&
      maxDiscount! >= minDiscount!;

  String get discountLabel {
    if (minDiscount != null && maxDiscount != null && minDiscount! > 0) {
      if (minDiscount!.round() == maxDiscount!.round()) {
        return '${minDiscount!.round()}% OFF';
      }
      return '${minDiscount!.round()}% - ${maxDiscount!.round()}% OFF';
    }
    if (discountPercentage > 0) {
      return '${discountPercentage.round()}% OFF';
    }
    return '0% OFF';
  }

  String get timeFormatted {
    if (startDatetime == null) return 'Flexible Slot';
    final formatter = DateFormat('hh:mm a');
    if (endDatetime != null) {
      return '${formatter.format(startDatetime!)} - ${formatter.format(endDatetime!)}';
    }
    return formatter.format(startDatetime!);
  }

  String get shift {
    if (startDatetime == null) return 'LUNCH';
    final hour = startDatetime!.hour;
    return hour < 17 ? 'LUNCH' : 'DINNER';
  }

  DailySlotModel copyWith({
    String? slotId,
    String? restaurantId,
    DateTime? startDatetime,
    DateTime? endDatetime,
    double? discountPercentage,
    double? minDiscount,
    double? maxDiscount,
    int? capacity,
  }) {
    return DailySlotModel(
      slotId: slotId ?? this.slotId,
      restaurantId: restaurantId ?? this.restaurantId,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      minDiscount: minDiscount ?? this.minDiscount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      capacity: capacity ?? this.capacity,
    );
  }
}
