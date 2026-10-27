import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DiningLocation {
  final String locality;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final bool isRealGps;

  const DiningLocation({
    required this.locality,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.isRealGps = false,
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
  String? _locationStatusMessage;

  DiningLocation get currentLocation => _currentLocation;
  bool get isLocating => _isLocating;
  String? get locationStatusMessage => _locationStatusMessage;

  LocationProvider() {
    _currentLocation = popularLocations.first;
  }

  void setLocation(DiningLocation location) {
    _currentLocation = location;
    _locationStatusMessage = null;
    notifyListeners();
  }

  /// Request actual device GPS fix and reverse-geocode to locality & city
  Future<bool> detectCurrentLocation() async {
    _isLocating = true;
    _locationStatusMessage = 'Acquiring GPS fix...';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationStatusMessage = 'Location services disabled on device';
        _isLocating = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationStatusMessage = 'Location permission denied by user';
          _isLocating = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationStatusMessage = 'Location permission permanently denied';
        _isLocating = false;
        notifyListeners();
        return false;
      }

      // Fetch actual GPS hardware position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Reverse geocode to street, locality, and city
      final List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String locality = (place.subLocality?.isNotEmpty ?? false)
            ? place.subLocality!
            : (place.locality?.isNotEmpty ?? false)
                ? place.locality!
                : (place.name?.isNotEmpty ?? false)
                    ? place.name!
                    : 'Current Area';

        final String city = (place.subAdministrativeArea?.isNotEmpty ?? false)
            ? place.subAdministrativeArea!
            : (place.locality?.isNotEmpty ?? false)
                ? place.locality!
                : 'Local';

        final String state = place.administrativeArea ?? 'India';

        _currentLocation = DiningLocation(
          locality: locality,
          city: city,
          state: state,
          latitude: position.latitude,
          longitude: position.longitude,
          isRealGps: true,
        );
        _locationStatusMessage = 'GPS fixed: $locality, $city';
      } else {
        _currentLocation = DiningLocation(
          locality: 'GPS Coords',
          city: '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}',
          state: 'Detected',
          latitude: position.latitude,
          longitude: position.longitude,
          isRealGps: true,
        );
      }

      _isLocating = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[LocationProvider] Real GPS fallback error: $e');
      _locationStatusMessage = 'GPS note: $e (using nearest dining hub)';
      _isLocating = false;
      notifyListeners();
      return false;
    }
  }
}
