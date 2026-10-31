import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Get all active restaurants
  Future<List<RestaurantModel>> getRestaurants() async {
    if (!FirebaseConfig.isConfigured) {
      return [];
    }
    final snapshot = await _firestore
        .collection('restaurants')
        .where('status', isEqualTo: 'ACTIVE')
        .get();

    return snapshot.docs
        .map((doc) => RestaurantModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .where('restaurant_id', isEqualTo: restaurantId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Try by document ID
      final doc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists) return null;
      return RestaurantModel.fromFirestore(doc);
    }

    return RestaurantModel.fromFirestore(snapshot.docs.first);
  }

  /// Search restaurants by name, cuisine, or location
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    // Firestore doesn't support full-text search natively, so we fetch all
    // active restaurants and filter client-side
    final allRestaurants = await getRestaurants();
    return allRestaurants
        .where((r) => r.matchesFilters(searchQuery: query))
        .toList();
  }

  /// Get restaurants filtered by criteria
  Future<List<RestaurantModel>> getFilteredRestaurants({
    String? searchQuery,
    String? cuisineFilter,
    bool? vegOnly,
    bool? hasBar,
    bool? isAc,
    bool? hasOffers,
  }) async {
    final allRestaurants = await getRestaurants();
    return allRestaurants
        .where((r) => r.matchesFilters(
              searchQuery: searchQuery,
              cuisineFilter: cuisineFilter,
              vegOnly: vegOnly,
              hasBar: hasBar,
              isAc: isAc,
              hasOffers: hasOffers,
            ))
        .toList();
  }

  /// Get available slots for a restaurant on a specific date
  Future<Map<String, int>> getAvailableSlots(
      String restaurantId, String date) async {
    final restaurant = await getRestaurantById(restaurantId);
    if (restaurant == null) return {};
    return restaurant.getAvailableSlots(date);
  }

  /// Get all unique cuisines from active restaurants
  Future<List<String>> getAllCuisines() async {
    final restaurants = await getRestaurants();
    final cuisineSet = <String>{};
    for (final restaurant in restaurants) {
      cuisineSet.addAll(restaurant.cuisines);
    }
    final cuisines = cuisineSet.toList();
    cuisines.sort();
    return cuisines;
  }

  /// Listen to restaurant changes in real-time
  Stream<List<RestaurantModel>> restaurantsStream() {
    return _firestore
        .collection('restaurants')
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RestaurantModel.fromFirestore(doc))
            .toList());
  }

  /// Listen to a single restaurant in real-time
  Stream<RestaurantModel?> restaurantStream(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return RestaurantModel.fromFirestore(doc);
    });
  }
}
