import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantOffer {
  final String offerId;
  final String title;
  final String type;
  final double value;

  RestaurantOffer({
    required this.offerId,
    required this.title,
    required this.type,
    required this.value,
  });

  factory RestaurantOffer.fromMap(Map<String, dynamic> data) {
    return RestaurantOffer(
      offerId: data['offer_id'] ?? '',
      title: data['title'] ?? '',
      type: data['type'] ?? 'percentage',
      value: (data['value'] ?? 0).toDouble(),
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

class RestaurantTimings {
  final String open;
  final String close;

  RestaurantTimings({
    required this.open,
    required this.close,
  });

  factory RestaurantTimings.fromMap(Map<String, dynamic> data) {
    return RestaurantTimings(
      open: data['open'] ?? '',
      close: data['close'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
    };
  }
}

class RestaurantLocation {
  final String address;
  final List<double> geoCoordinates;

  RestaurantLocation({
    required this.address,
    required this.geoCoordinates,
  });

  factory RestaurantLocation.fromMap(Map<String, dynamic> data) {
    return RestaurantLocation(
      address: data['address'] ?? '',
      geoCoordinates: List<double>.from(
          (data['geo_coordinates'] ?? [0.0, 0.0]).map((e) => (e as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'geo_coordinates': geoCoordinates,
    };
  }
}

class RestaurantVisuals {
  final String heroImage;
  final List<String> ambience;
  final List<String> menuImages;

  RestaurantVisuals({
    required this.heroImage,
    required this.ambience,
    required this.menuImages,
  });

  factory RestaurantVisuals.fromMap(Map<String, dynamic> data) {
    return RestaurantVisuals(
      heroImage: data['hero_image'] ?? '',
      ambience: List<String>.from(data['ambience'] ?? []),
      menuImages: List<String>.from(data['menu_images'] ?? []),
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

  RestaurantAttributes({
    required this.isVegOnly,
    required this.hasBar,
    required this.isAc,
    required this.parkingAvailable,
  });

  factory RestaurantAttributes.fromMap(Map<String, dynamic> data) {
    return RestaurantAttributes(
      isVegOnly: data['is_veg_only'] ?? false,
      hasBar: data['has_bar'] ?? false,
      isAc: data['is_ac'] ?? false,
      parkingAvailable: data['parking_available'] ?? false,
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

class RestaurantRating {
  final double average;
  final int totalReviews;

  RestaurantRating({
    required this.average,
    required this.totalReviews,
  });

  factory RestaurantRating.fromMap(Map<String, dynamic> data) {
    return RestaurantRating(
      average: (data['average'] ?? 0).toDouble(),
      totalReviews: data['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'average': average,
      'total_reviews': totalReviews,
    };
  }
}

class RestaurantModel {
  final String restaurantId;
  final String name;
  final String upiId;
  final String fssaiNumber;
  final RestaurantLocation location;
  final int costForTwo;
  final Map<String, RestaurantTimings> timings;
  final RestaurantVisuals visuals;
  final RestaurantAttributes attributes;
  final List<String> cuisines;
  final List<RestaurantOffer> activeOffers;
  final Map<String, Map<String, int>> dailySlots;
  final RestaurantRating rating;
  final String status;

  RestaurantModel({
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

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse timings
    final timingsData = data['timings'] as Map<String, dynamic>? ?? {};
    final timingsMap = <String, RestaurantTimings>{};
    timingsData.forEach((key, value) {
      timingsMap[key] = RestaurantTimings.fromMap(value as Map<String, dynamic>);
    });

    // Parse daily_slots
    final slotsData = data['daily_slots'] as Map<String, dynamic>? ?? {};
    final slotsMap = <String, Map<String, int>>{};
    slotsData.forEach((dateKey, dateValue) {
      final daySlots = <String, int>{};
      (dateValue as Map<String, dynamic>).forEach((timeKey, count) {
        daySlots[timeKey] = (count as num).toInt();
      });
      slotsMap[dateKey] = daySlots;
    });

    // Parse active_offers
    final offersData = data['active_offers'] as List<dynamic>? ?? [];
    final offers = offersData
        .map((o) => RestaurantOffer.fromMap(o as Map<String, dynamic>))
        .toList();

    return RestaurantModel(
      restaurantId: data['restaurant_id'] ?? doc.id,
      name: data['name'] ?? '',
      upiId: data['upi_id'] ?? '',
      fssaiNumber: data['fssai_number'] ?? '',
      location: RestaurantLocation.fromMap(
          data['location'] as Map<String, dynamic>? ?? {}),
      costForTwo: (data['cost_for_two'] ?? 0).toInt(),
      timings: timingsMap,
      visuals: RestaurantVisuals.fromMap(
          data['visuals'] as Map<String, dynamic>? ?? {}),
      attributes: RestaurantAttributes.fromMap(
          data['attributes'] as Map<String, dynamic>? ?? {}),
      cuisines: List<String>.from(data['cuisines'] ?? []),
      activeOffers: offers,
      dailySlots: slotsMap,
      rating: RestaurantRating.fromMap(
          data['rating'] as Map<String, dynamic>? ?? {}),
      status: data['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toFirestore() {
    final timingsMap = <String, dynamic>{};
    timings.forEach((key, value) {
      timingsMap[key] = value.toMap();
    });

    final slotsMap = <String, dynamic>{};
    dailySlots.forEach((dateKey, dateValue) {
      slotsMap[dateKey] = dateValue;
    });

    return {
      'restaurant_id': restaurantId,
      'name': name,
      'upi_id': upiId,
      'fssai_number': fssaiNumber,
      'location': location.toMap(),
      'cost_for_two': costForTwo,
      'timings': timingsMap,
      'visuals': visuals.toMap(),
      'attributes': attributes.toMap(),
      'cuisines': cuisines,
      'active_offers': activeOffers.map((o) => o.toMap()).toList(),
      'daily_slots': slotsMap,
      'rating': rating.toMap(),
      'status': status,
    };
  }

  /// Get available slots for a given date (only slots with count > 0)
  Map<String, int> getAvailableSlots(String date) {
    final daySlots = dailySlots[date] ?? {};
    final available = <String, int>{};
    daySlots.forEach((time, count) {
      if (count > 0) {
        available[time] = count;
      }
    });
    return available;
  }

  /// Check if restaurant matches given filters
  bool matchesFilters({
    String? searchQuery,
    String? cuisineFilter,
    bool? vegOnly,
    bool? hasBar,
    bool? isAc,
    bool? hasOffers,
  }) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final nameMatch = name.toLowerCase().contains(query);
      final cuisineMatch =
          cuisines.any((c) => c.toLowerCase().contains(query));
      final locationMatch = location.address.toLowerCase().contains(query);
      if (!nameMatch && !cuisineMatch && !locationMatch) return false;
    }

    if (cuisineFilter != null && cuisineFilter.isNotEmpty) {
      if (!cuisines.any(
          (c) => c.toLowerCase() == cuisineFilter.toLowerCase())) {
        return false;
      }
    }

    if (vegOnly == true && !attributes.isVegOnly) return false;
    if (hasBar == true && !attributes.hasBar) return false;
    if (isAc == true && !attributes.isAc) return false;
    if (hasOffers == true && activeOffers.isEmpty) return false;

    return true;
  }
}
