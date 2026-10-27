import 'package:flutter/material.dart';

class DiningLocation {
  final String locality;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const DiningLocation({
    required this.locality,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  String get shortLabel => '$locality, $city';
  String get fullAddress => '$locality, $city, $state';
}

class LocationProvider extends ChangeNotifier {
  static const List<DiningLocation> popularLocations = [
    // Pune
    DiningLocation(locality: 'Koregaon Park', city: 'Pune', state: 'Maharashtra', latitude: 18.5362, longitude: 73.8940, isDefault: true),
    DiningLocation(locality: 'Camp', city: 'Pune', state: 'Maharashtra', latitude: 18.5196, longitude: 73.8773),
    DiningLocation(locality: 'Kalyani Nagar', city: 'Pune', state: 'Maharashtra', latitude: 18.5463, longitude: 73.9033),
    DiningLocation(locality: 'FC Road', city: 'Pune', state: 'Maharashtra', latitude: 18.5204, longitude: 73.8407),
    DiningLocation(locality: 'Baner', city: 'Pune', state: 'Maharashtra', latitude: 18.5590, longitude: 73.7868),
    DiningLocation(locality: 'Viman Nagar', city: 'Pune', state: 'Maharashtra', latitude: 18.5679, longitude: 73.9143),
    DiningLocation(locality: 'Balewadi High Street', city: 'Pune', state: 'Maharashtra', latitude: 18.5750, longitude: 73.7740),
    // Mumbai
    DiningLocation(locality: 'Bandra West', city: 'Mumbai', state: 'Maharashtra', latitude: 19.0596, longitude: 72.8295),
    DiningLocation(locality: 'BKC', city: 'Mumbai', state: 'Maharashtra', latitude: 19.0662, longitude: 72.8687),
    DiningLocation(locality: 'Lower Parel', city: 'Mumbai', state: 'Maharashtra', latitude: 18.9986, longitude: 72.8311),
    DiningLocation(locality: 'Juhu', city: 'Mumbai', state: 'Maharashtra', latitude: 19.1075, longitude: 72.8263),
    // Bengaluru
    DiningLocation(locality: 'Indiranagar', city: 'Bengaluru', state: 'Karnataka', latitude: 12.9784, longitude: 77.6408),
    DiningLocation(locality: 'Koramangala', city: 'Bengaluru', state: 'Karnataka', latitude: 12.9352, longitude: 77.6245),
    // Delhi NCR
    DiningLocation(locality: 'Connaught Place', city: 'New Delhi', state: 'Delhi', latitude: 28.6315, longitude: 77.2167),
    DiningLocation(locality: 'Cyber Hub', city: 'Gurugram', state: 'Haryana', latitude: 28.4986, longitude: 77.0890),
  ];

  late DiningLocation _currentLocation;
  bool _isLocating = false;

  DiningLocation get currentLocation => _currentLocation;
  bool get isLocating => _isLocating;

  LocationProvider() {
    _currentLocation = popularLocations.first;
  }

  void setLocation(DiningLocation location) {
    _currentLocation = location;
    notifyListeners();
  }

  Future<void> detectCurrentLocation() async {
    _isLocating = true;
    notifyListeners();
    // Simulate high-precision GPS lock
    await Future.delayed(const Duration(milliseconds: 600));
    _currentLocation = popularLocations.first; // Locked to current locality
    _isLocating = false;
    notifyListeners();
  }
}
