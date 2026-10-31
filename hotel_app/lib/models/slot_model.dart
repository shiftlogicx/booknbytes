import 'package:intl/intl.dart';

class DailySlotModel {
  final String slotId;
  final String restaurantId;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final double discountPercentage;
  final int capacity;

  const DailySlotModel({
    required this.slotId,
    required this.restaurantId,
    this.startDatetime,
    this.endDatetime,
    required this.discountPercentage,
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

    return DailySlotModel(
      slotId: map['slot_id']?.toString() ?? '',
      restaurantId: map['restaurant_id']?.toString() ?? '',
      startDatetime: start,
      endDatetime: end,
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
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
      'capacity': capacity,
    };
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
    int? capacity,
  }) {
    return DailySlotModel(
      slotId: slotId ?? this.slotId,
      restaurantId: restaurantId ?? this.restaurantId,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      capacity: capacity ?? this.capacity,
    );
  }
}
