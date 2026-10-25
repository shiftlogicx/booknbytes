import 'package:cloud_firestore/cloud_firestore.dart';

class GeoLocation {
  final String address;
  final List<double> geoCoordinates;

  const GeoLocation({
    required this.address,
    required this.geoCoordinates,
  });

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      address: map['address'] ?? '',
      geoCoordinates: List<double>.from(map['geo_coordinates'] ?? [0.0, 0.0]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'geo_coordinates': geoCoordinates,
    };
  }
}

class RestaurantTimings {
  final TimeSlotRange? lunch;
  final TimeSlotRange? dinner;

  const RestaurantTimings({this.lunch, this.dinner});

  factory RestaurantTimings.fromMap(Map<String, dynamic> map) {
    return RestaurantTimings(
      lunch: map['lunch'] != null
          ? TimeSlotRange.fromMap(Map<String, dynamic>.from(map['lunch']))
          : null,
      dinner: map['dinner'] != null
          ? TimeSlotRange.fromMap(Map<String, dynamic>.from(map['dinner']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (lunch != null) 'lunch': lunch!.toMap(),
      if (dinner != null) 'dinner': dinner!.toMap(),
    };
  }
}

class TimeSlotRange {
  final String open;
  final String close;

  const TimeSlotRange({required this.open, required this.close});

  factory TimeSlotRange.fromMap(Map<String, dynamic> map) {
    return TimeSlotRange(
      open: map['open'] ?? '',
      close: map['close'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'open': open, 'close': close};
  }
}

class RestaurantVisuals {
  final String heroImage;
  final List<String> ambience;
  final List<String> menuImages;

  const RestaurantVisuals({
    required this.heroImage,
    required this.ambience,
    required this.menuImages,
  });

  factory RestaurantVisuals.fromMap(Map<String, dynamic> map) {
    return RestaurantVisuals(
      heroImage: map['hero_image'] ?? '',
      ambience: List<String>.from(map['ambience'] ?? []),
      menuImages: List<String>.from(map['menu_images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hero_image': heroImage,
      'ambience': ambience,
      'menu_images': menuImages,
    };
  }
}

class RestaurantAttributes {
  final bool isVegOnly;
  final bool hasBar;
  final bool isAc;
  final bool parkingAvailable;

  const RestaurantAttributes({
    required this.isVegOnly,
    required this.hasBar,
    required this.isAc,
    required this.parkingAvailable,
  });

  factory RestaurantAttributes.fromMap(Map<String, dynamic> map) {
    return RestaurantAttributes(
      isVegOnly: map['is_veg_only'] ?? false,
      hasBar: map['has_bar'] ?? false,
      isAc: map['is_ac'] ?? false,
      parkingAvailable: map['parking_available'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_veg_only': isVegOnly,
      'has_bar': hasBar,
      'is_ac': isAc,
      'parking_available': parkingAvailable,
    };
  }
}

class ActiveOffer {
  final String offerId;
  final String title;
  final String type;
  final num value;

  const ActiveOffer({
    required this.offerId,
    required this.title,
    required this.type,
    required this.value,
  });

  factory ActiveOffer.fromMap(Map<String, dynamic> map) {
    return ActiveOffer(
      offerId: map['offer_id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      value: map['value'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'offer_id': offerId,
      'title': title,
      'type': type,
      'value': value,
    };
  }
}

class RestaurantRating {
  final double average;
  final int totalReviews;

  const RestaurantRating({required this.average, required this.totalReviews});

  factory RestaurantRating.fromMap(Map<String, dynamic> map) {
    return RestaurantRating(
      average: (map['average'] ?? 0.0).toDouble(),
      totalReviews: (map['total_reviews'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'average': average, 'total_reviews': totalReviews};
  }
}

class RestaurantModel {
  final String restaurantId;
  final String name;
  final String upiId;
  final String fssaiNumber;
  final GeoLocation location;
  final int costForTwo;
  final RestaurantTimings timings;
  final RestaurantVisuals visuals;
  final RestaurantAttributes attributes;
  final List<String> cuisines;
  final List<ActiveOffer> activeOffers;
  final Map<String, Map<String, int>> dailySlots;
  final RestaurantRating rating;
  final String status;

  const RestaurantModel({
    required this.restaurantId,
    required this.name,
    required this.upiId,
    required this.fssaiNumber,
    required this.location,
    required this.costForTwo,
    required this.timings,
    required this.visuals,
    required this.attributes,
    required this.cuisines,
    required this.activeOffers,
    required this.dailySlots,
    required this.rating,
    required this.status,
  });

  bool get isActive => status == 'ACTIVE';

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantModel.fromMap(data);
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    // Parse daily_slots
    final rawSlots = map['daily_slots'] as Map<String, dynamic>? ?? {};
    final parsedSlots = <String, Map<String, int>>{};
    for (final dateEntry in rawSlots.entries) {
      final slotMap = dateEntry.value as Map<String, dynamic>? ?? {};
      parsedSlots[dateEntry.key] = slotMap.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    }

    // Parse active_offers
    final rawOffers = map['active_offers'] as List<dynamic>? ?? [];
    final parsedOffers = rawOffers
        .map((o) => ActiveOffer.fromMap(Map<String, dynamic>.from(o)))
        .toList();

    return RestaurantModel(
      restaurantId: map['restaurant_id'] ?? '',
      name: map['name'] ?? '',
      upiId: map['upi_id'] ?? '',
      fssaiNumber: map['fssai_number'] ?? '',
      location: GeoLocation.fromMap(
        Map<String, dynamic>.from(map['location'] ?? {'address': '', 'geo_coordinates': [0.0, 0.0]}),
      ),
      costForTwo: (map['cost_for_two'] ?? 0).toInt(),
      timings: RestaurantTimings.fromMap(
        Map<String, dynamic>.from(map['timings'] ?? {}),
      ),
      visuals: RestaurantVisuals.fromMap(
        Map<String, dynamic>.from(map['visuals'] ?? {'hero_image': '', 'ambience': [], 'menu_images': []}),
      ),
      attributes: RestaurantAttributes.fromMap(
        Map<String, dynamic>.from(map['attributes'] ?? {}),
      ),
      cuisines: List<String>.from(map['cuisines'] ?? []),
      activeOffers: parsedOffers,
      dailySlots: parsedSlots,
      rating: RestaurantRating.fromMap(
        Map<String, dynamic>.from(map['rating'] ?? {'average': 0.0, 'total_reviews': 0}),
      ),
      status: map['status'] ?? 'INACTIVE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurant_id': restaurantId,
      'name': name,
      'upi_id': upiId,
      'fssai_number': fssaiNumber,
      'location': location.toMap(),
      'cost_for_two': costForTwo,
      'timings': timings.toMap(),
      'visuals': visuals.toMap(),
      'attributes': attributes.toMap(),
      'cuisines': cuisines,
      'active_offers': activeOffers.map((o) => o.toMap()).toList(),
      'daily_slots': dailySlots.map(
        (key, value) => MapEntry(key, value),
      ),
      'rating': rating.toMap(),
      'status': status,
    };
  }

  /// Get available slots for a given date
  Map<String, int> getSlotsForDate(String date) {
    return dailySlots[date] ?? {};
  }

  /// Total available slots for a given date
  int totalAvailableSlots(String date) {
    final slots = getSlotsForDate(date);
    return slots.values.fold(0, (sum, count) => sum + count);
  }
}
