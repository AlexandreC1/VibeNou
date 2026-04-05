import 'dart:math';

/// Geohash utility for location-based Firestore queries.
///
/// Encodes latitude/longitude into a geohash string that enables
/// efficient range queries in Firestore instead of fetching all users.
///
/// Precision guide:
///   1 = ~5000km, 2 = ~1250km, 3 = ~156km, 4 = ~39km,
///   5 = ~5km, 6 = ~1.2km, 7 = ~150m, 8 = ~40m
class Geohash {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode lat/lng to a geohash string at given precision (default 7).
  static String encode(double latitude, double longitude, {int precision = 7}) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    bool isLng = true;
    int bit = 0;
    int ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      final mid = isLng
          ? (lngMin + lngMax) / 2
          : (latMin + latMax) / 2;

      if (isLng) {
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isLng = !isLng;
      bit++;

      if (bit == 5) {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Get the geohash precision needed for a given radius in km.
  /// Returns a precision that covers at least the given radius.
  static int precisionForRadius(double radiusKm) {
    if (radiusKm >= 5000) return 1;
    if (radiusKm >= 1250) return 2;
    if (radiusKm >= 156) return 3;
    if (radiusKm >= 39) return 4;
    if (radiusKm >= 5) return 5;
    if (radiusKm >= 1.2) return 6;
    if (radiusKm >= 0.15) return 7;
    return 8;
  }

  /// Get neighboring geohash prefixes that cover the search area.
  /// Returns a list of geohash prefixes to query.
  static List<String> getQueryBounds(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    final precision = precisionForRadius(radiusKm);
    final centerHash = encode(latitude, longitude, precision: precision);

    // Get neighbors to cover the area around the center
    final neighbors = _getNeighbors(centerHash);
    return [centerHash, ...neighbors];
  }

  /// Get the 8 neighboring geohashes of a given geohash.
  static List<String> _getNeighbors(String hash) {
    final bounds = _decodeBounds(hash);
    final lat = (bounds[0] + bounds[1]) / 2;
    final lng = (bounds[2] + bounds[3]) / 2;
    final latErr = (bounds[1] - bounds[0]) / 2;
    final lngErr = (bounds[3] - bounds[2]) / 2;

    final precision = hash.length;
    return [
      encode(lat + 2 * latErr, lng, precision: precision),             // N
      encode(lat + 2 * latErr, lng + 2 * lngErr, precision: precision), // NE
      encode(lat, lng + 2 * lngErr, precision: precision),             // E
      encode(lat - 2 * latErr, lng + 2 * lngErr, precision: precision), // SE
      encode(lat - 2 * latErr, lng, precision: precision),             // S
      encode(lat - 2 * latErr, lng - 2 * lngErr, precision: precision), // SW
      encode(lat, lng - 2 * lngErr, precision: precision),             // W
      encode(lat + 2 * latErr, lng - 2 * lngErr, precision: precision), // NW
    ];
  }

  /// Decode a geohash into [latMin, latMax, lngMin, lngMax] bounds.
  static List<double> _decodeBounds(String hash) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    bool isLng = true;

    for (int i = 0; i < hash.length; i++) {
      final ch = _base32.indexOf(hash[i]);
      for (int bit = 4; bit >= 0; bit--) {
        if (isLng) {
          final mid = (lngMin + lngMax) / 2;
          if ((ch >> bit) & 1 == 1) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if ((ch >> bit) & 1 == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isLng = !isLng;
      }
    }

    return [latMin, latMax, lngMin, lngMax];
  }

  /// Get the range [start, end] for a Firestore query on a geohash prefix.
  /// Use: .where('geohash', isGreaterThanOrEqualTo: start)
  ///      .where('geohash', isLessThan: end)
  static List<String> getQueryRange(String prefix) {
    final end = prefix.substring(0, prefix.length - 1) +
        String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);
    return [prefix, end];
  }

  /// Calculate distance between two points using Haversine formula (in km).
  static double distanceKm(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
