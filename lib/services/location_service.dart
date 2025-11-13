import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location service for handling GPS coordinates and permissions
/// Provides location tracking, geocoding, and permission management
class LocationService {
  DateTime? _lastLocationUpdate;
  static const Duration _minUpdateInterval = Duration(minutes: 5);

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (kDebugMode) {
      print('📍 Location services enabled: $enabled');
    }
    return enabled;
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    if (kDebugMode) {
      print('📍 Location permission: $permission');
    }
    return permission;
  }

  /// Request location permission from user
  Future<LocationPermission> requestPermission() async {
    if (kDebugMode) {
      print('📍 Requesting location permission');
    }
    final permission = await Geolocator.requestPermission();
    if (kDebugMode) {
      print('📍 Location permission result: $permission');
    }
    return permission;
  }

  /// Check if we should update location based on time throttling
  bool shouldUpdateLocation() {
    if (_lastLocationUpdate == null) return true;

    final timeSinceLastUpdate = DateTime.now().difference(_lastLocationUpdate!);
    return timeSinceLastUpdate >= _minUpdateInterval;
  }

  /// Get current GPS position with permission handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('❌ Location services are disabled');
        }
        return null;
      }

      // Check and request permission
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('❌ Location permission denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('❌ Location permission permanently denied');
        }
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastLocationUpdate = DateTime.now();

      if (kDebugMode) {
        print('✅ Current position: (${position.latitude}, ${position.longitude})');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting current position: $e');
      }
      return null;
    }
  }

  /// Get address information from GPS coordinates using reverse geocoding
  Future<Map<String, String>?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (kDebugMode) {
        print('🗺️  Reverse geocoding: ($latitude, $longitude)');
      }

      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        if (kDebugMode) {
          print('⚠️  No placemark found');
        }
        return null;
      }

      final place = placemarks.first;

      final addressInfo = {
        'city': place.locality ?? place.subAdministrativeArea ?? '',
        'country': place.country ?? '',
        'street': place.street ?? '',
        'postalCode': place.postalCode ?? '',
        'administrativeArea': place.administrativeArea ?? '',
      };

      if (kDebugMode) {
        print('✅ Address: ${addressInfo['city']}, ${addressInfo['country']}');
      }

      return addressInfo;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting address from coordinates: $e');
      }
      return null;
    }
  }

  /// Stream of position updates with distance filter
  /// Only updates when user moves more than 100 meters
  Stream<Position> getPositionStream() {
    if (kDebugMode) {
      print('📍 Starting position stream');
    }

    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calculate distance between two GPS coordinates in kilometers
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening location settings: $e');
      }
      return false;
    }
  }

  /// Open app settings for location permission
  Future<bool> openAppSettings() async {
    try {
      return await Permission.location.request().isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Get last known position (faster but may be stale)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting last known position: $e');
      }
      return null;
    }
  }
}
