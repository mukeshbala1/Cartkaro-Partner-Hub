import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MapboxService {
  // Public Mapbox Access Token (Configurable via --dart-define=MAPBOX_ACCESS_TOKEN=pk.eyJ...)
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'YOUR_MAPBOX_PUBLIC_TOKEN',
  );

  // Standard Mapbox Tile Style URLs
  static String getStyleTileUrl({String style = 'streets-v12'}) {
    if (mapboxAccessToken.startsWith('pk.')) {
      return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';
    }
    // High-contrast OpenStreetMap raster tile fallback if no Mapbox token present
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Reverse Geocode latitude and longitude using Mapbox Places API
  /// Returns a Map with 'address', 'area', 'city', 'state', 'pincode'
  static Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    Map<String, String> geo = {};

    // 1. Mapbox API Reverse Geocoding
    if (mapboxAccessToken.startsWith('pk.')) {
      try {
        final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$mapboxAccessToken&types=address,poi,neighborhood,locality,place,district,region,postcode',
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'CartKaroPartnerHub/1.0',
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>? ?? [];

          if (features.isNotEmpty) {
            String fullAddress = '';
            String area = '';
            String city = '';
            String state = '';
            String pincode = '';

            for (var feature in features) {
              final placeType = (feature['place_type'] as List<dynamic>? ?? []).firstOrNull as String?;
              final text = feature['text'] as String? ?? '';
              final placeName = feature['place_name'] as String? ?? '';

              if (fullAddress.isEmpty && (placeType == 'address' || placeType == 'poi')) {
                fullAddress = placeName.split(',').take(3).join(', ').trim();
              } else if (fullAddress.isEmpty && features.first == feature) {
                fullAddress = placeName.split(',').take(3).join(', ').trim();
              }

              if (placeType == 'neighborhood' || placeType == 'locality') {
                if (area.isEmpty) area = text;
              } else if (placeType == 'place' || placeType == 'district') {
                if (city.isEmpty) city = text;
              } else if (placeType == 'region') {
                if (state.isEmpty) state = text;
              } else if (placeType == 'postcode') {
                if (pincode.isEmpty) pincode = text;
              }
            }

            if (fullAddress.isNotEmpty) {
              geo = {
                'address': fullAddress,
                'area': area,
                'city': city,
                'state': state,
                'pincode': pincode,
              };
            }
          }
        }
      } catch (e) {
        debugPrint('Mapbox API geocoding exception: $e');
      }
    }

    // 2. OpenStreetMap Fallback if Mapbox returned empty or failed
    if (geo.isEmpty || (geo['address']?.trim().length ?? 0) < 5) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'CartKaroPartnerHub/1.0',
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>? ?? {};
          final String displayName = data['display_name'] as String? ?? '';

          String house = address['house_number'] ?? address['building'] ?? address['amenity'] ?? address['shop'] ?? address['office'] ?? '';
          String road = address['road'] ?? address['pedestrian'] ?? address['footway'] ?? address['path'] ?? '';
          String suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? '';
          String subdistrict = address['subdistrict'] ?? address['district'] ?? '';

          List<String> addrParts = [];
          for (String s in [house, road, suburb, subdistrict]) {
            if (s.trim().isNotEmpty && !addrParts.any((item) => item.toLowerCase() == s.trim().toLowerCase())) {
              addrParts.add(s.trim());
            }
          }
          String fullAddr = addrParts.join(', ');

          if (fullAddr.isEmpty || fullAddr.length < 5) {
            if (displayName.isNotEmpty) {
              List<String> parts = displayName.split(',').map((e) => e.trim()).toList();
              if (parts.length > 2) parts.removeLast();
              fullAddr = parts.join(', ');
            }
          }

          String area = suburb.isNotEmpty ? suburb : subdistrict;
          String city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state_district'] ?? '';
          String state = address['state'] ?? '';
          String pincode = address['postcode'] ?? '';

          geo = {
            'address': fullAddr.isNotEmpty ? fullAddr : displayName,
            'area': area,
            'city': city,
            'state': state,
            'pincode': pincode,
          };
        }
      } catch (e) {
        debugPrint('OSM geocoding fallback error: $e');
      }
    }

    return geo;
  }
}
