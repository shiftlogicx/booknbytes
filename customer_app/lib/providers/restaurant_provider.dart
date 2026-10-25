import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  RestaurantModel? _selectedRestaurant;
  List<String> _allCuisines = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';
  String? _selectedCuisine;
  bool _vegOnly = false;
  bool _hasBar = false;
  bool _isAc = false;
  bool _hasOffers = false;

  // Getters
  List<RestaurantModel> get restaurants => _filteredRestaurants;
  List<RestaurantModel> get allRestaurants => _restaurants;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;
  List<String> get allCuisines => _allCuisines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCuisine => _selectedCuisine;
  bool get vegOnly => _vegOnly;
  bool get hasBar => _hasBar;
  bool get isAc => _isAc;
  bool get hasOffers => _hasOffers;
  bool get hasActiveFilters =>
      _selectedCuisine != null || _vegOnly || _hasBar || _isAc || _hasOffers;

  /// Fetch all restaurants
  Future<void> fetchRestaurants() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _restaurants = await _restaurantService.getRestaurants();
      _allCuisines = await _restaurantService.getAllCuisines();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load restaurants: ${e.toString()}';
      _filteredRestaurants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set search query and filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set cuisine filter
  void setCuisineFilter(String? cuisine) {
    if (_selectedCuisine == cuisine) {
      _selectedCuisine = null;
    } else {
      _selectedCuisine = cuisine;
    }
    _applyFilters();
    notifyListeners();
  }

  /// Toggle veg-only filter
  void toggleVegOnly() {
    _vegOnly = !_vegOnly;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle has-bar filter
  void toggleHasBar() {
    _hasBar = !_hasBar;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle AC filter
  void toggleIsAc() {
    _isAc = !_isAc;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle offers filter
  void toggleHasOffers() {
    _hasOffers = !_hasOffers;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCuisine = null;
    _vegOnly = false;
    _hasBar = false;
    _isAc = false;
    _hasOffers = false;
    _applyFilters();
    notifyListeners();
  }

  /// Apply all active filters
  void _applyFilters() {
    _filteredRestaurants = _restaurants.where((restaurant) {
      return restaurant.matchesFilters(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        cuisineFilter: _selectedCuisine,
        vegOnly: _vegOnly ? true : null,
        hasBar: _hasBar ? true : null,
        isAc: _isAc ? true : null,
        hasOffers: _hasOffers ? true : null,
      );
    }).toList();
  }

  /// Select a restaurant
  void selectRestaurant(RestaurantModel restaurant) {
    _selectedRestaurant = restaurant;
    notifyListeners();
  }

  /// Clear selected restaurant
  void clearSelectedRestaurant() {
    _selectedRestaurant = null;
    notifyListeners();
  }

  /// Fetch a single restaurant by ID
  Future<RestaurantModel?> fetchRestaurantById(String restaurantId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedRestaurant =
          await _restaurantService.getRestaurantById(restaurantId);
      return _selectedRestaurant;
    } catch (e) {
      _errorMessage =
          'Failed to load restaurant details: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
