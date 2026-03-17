import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static const String _apiKey = "AIzaSyC589dfLvYXf7KLBKBXEoBOeKewkQCHf4M";

  static Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];
    
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&components=country:ca";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> getRouteDetails(List<String> addresses) async {
    if (addresses.length < 2) return {'distance': 0.0, 'duration': ''};

    final String origin = Uri.encodeComponent(addresses.first);
    final String destination = Uri.encodeComponent(addresses.last);
    String waypoints = "";

    if (addresses.length > 2) {
      waypoints = "&waypoints=${addresses.sublist(1, addresses.length - 1)
          .map((e) => Uri.encodeComponent(e))
          .join('|')}";
    }

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination$waypoints&key=$_apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        double totalDistance = 0;
        int totalSeconds = 0;

        for (var route in data['routes']) {
          for (var leg in route['legs']) {
            totalDistance += leg['distance']['value']; // meters
            totalSeconds += (leg['duration']['value'] as num).toInt(); // seconds
          }
        }

        return {
          'distance': totalDistance / 1000, // km
          'duration': _formatSeconds(totalSeconds),
          'points': _decodePolyline(data['routes'][0]['overview_polyline']['points']),
        };
      }
    }
    return {'distance': 0.0, 'duration': ''};
  }

  static String _formatSeconds(int seconds) {
    if (seconds < 60) return "$seconds sec";
    int mins = (seconds / 60).round();
    if (mins < 60) return "$mins mins";
    int hours = (mins / 60).floor();
    int remainingMins = mins % 60;
    return "${hours}h ${remainingMins}m";
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
