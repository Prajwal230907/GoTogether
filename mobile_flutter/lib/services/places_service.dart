import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({required this.placeId, required this.description});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;

  PlaceDetails({required this.lat, required this.lng, required this.formattedAddress});
}

class PlacesService {
  final String apiKey;
  final String sessionToken; // Optional: Manage session tokens for billing optimization

  PlacesService(this.apiKey) : sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  Future<List<PlaceSuggestion>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    final request = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$input'
        '&key=$apiKey'
        '&components=country:in'; // Restrict to India for this app context if preferred

    try {
      print('Fetching places for: "$input"'); // Log the attempt
      final response = await http.get(Uri.parse(request)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out. Check internet connection.');
        },
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Log the full body for debug

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          return (result['predictions'] as List)
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
        }
        if (result['status'] == 'ZERO_RESULTS') {
          return [];
        }
        // Throw specific API errors to the UI
        throw Exception('${result['status']}: ${result['error_message'] ?? "Unknown API Error"}');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Places Error Trace: $e');
      throw Exception(e.toString().replaceAll('Exception: ', '')); // Clean up error message
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final request = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,formatted_address'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          final geometry = result['result']['geometry']['location'];
          final address = result['result']['formatted_address'];
          return PlaceDetails(
            lat: geometry['lat'],
            lng: geometry['lng'],
            formattedAddress: address,
          );
        }
      }
      return null;
    } catch (e) {
      print('Details Error: $e');
      return null;
    }
  }
}
