import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ServiceCenter {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String distance;

  ServiceCenter({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.distance,
  });
}

class MapService {
  /// Fetches the user's current location, requesting permissions if necessary.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Fallback for Windows desktop or timeout
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Fetches real car repair shops within a [radiusMeters] using OpenStreetMap Overpass API.
  static Future<List<ServiceCenter>> getNearbyMechanics(double lat, double lng, {int radiusMeters = 5000}) async {
    final query = '''
      [out:json];
      node(around:\$radiusMeters, \$lat, \$lng)["shop"="car_repair"];
      out;
    ''';
    
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    try {
      final response = await http.post(url, body: query);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;
        
        final Distance distanceTool = const Distance();
        final List<ServiceCenter> centers = [];
        
        for (var el in elements) {
          final tags = el['tags'] ?? {};
          final name = tags['name'] ?? tags['brand'] ?? 'Автосервис СТО';
          final elLat = el['lat'] as double;
          final elLon = el['lon'] as double;
          
          final distMeters = distanceTool.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(elLat, elLon));
          final distString = distMeters < 1000 
              ? '\${distMeters.toInt()} м' 
              : '\${(distMeters / 1000).toStringAsFixed(1)} км';
          
          // Try to guess category based on name
          String category = 'diagnostics';
          final lowerName = name.toLowerCase();
          if (lowerName.contains('электр')) {
            category = 'electrician';
          } else if (lowerName.contains('мотор') || lowerName.contains('двигател')) {
            category = 'engine';
          }
          
          centers.add(ServiceCenter(
            name: name,
            category: category,
            lat: elLat,
            lng: elLon,
            rating: 4.0 + (el.hashCode % 10) / 10.0, // Mock rating since OSM rarely has ratings
            distance: distString,
          ));
        }
        
        // Sort by distance
        centers.sort((a, b) {
          final distA = distanceTool.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(a.lat, a.lng));
          final distB = distanceTool.as(LengthUnit.Meter, LatLng(lat, lng), LatLng(b.lat, b.lng));
          return distA.compareTo(distB);
        });
        
        return centers;
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }
}
