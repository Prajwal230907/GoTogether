import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;
  final double lat;
  final double lng;

  PlaceSuggestion({
    required this.placeId, 
    required this.description,
    required this.lat,
    required this.lng,
  });
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;

  PlaceDetails({required this.lat, required this.lng, required this.formattedAddress});
}

class PlacesService {
  // LocationIQ API Key
  final String apiKey = "pk.3e95f8f7b048b1c0fd1a1d96a632cb5e"; 

  PlacesService(String ignoredApiKey); 

  Future<List<PlaceSuggestion>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    final request = 'https://api.locationiq.com/v1/autocomplete?key=$apiKey&q=$input&limit=5&format=json';

    try {
      print('Fetching places for: "$input"');
      final response = await http.get(Uri.parse(request)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out. Check internet connection.');
        },
      );
      
      if (response.statusCode == 200) {
        final List result = json.decode(response.body);
        return result.map((p) => PlaceSuggestion(
          placeId: p['place_id'].toString(),
          description: p['display_name'],
          lat: double.parse(p['lat']),
          lng: double.parse(p['lon']),
        )).toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Places Error Trace: $e');
      return [];
    }
  }

  // Deprecated: We get coordinates directly from suggestions now
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    return null;
  }
}
