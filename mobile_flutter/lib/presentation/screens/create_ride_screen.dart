import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../services/places_service.dart';

// Move API Key to a secure config later. Using the one from AndroidManifest for now.
const String _kGoogleMapsApiKey = 'AIzaSyCipZbhcVoM-gLvoE_vJV_Bmd5BZdm3r1I';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _fareController = TextEditingController();
  final _seatsController = TextEditingController(text: '3');
  
  bool _isLoading = false;
  final _placesService = PlacesService(_kGoogleMapsApiKey);

  // Store selected location details
  PlaceDetails? _originLocation;
  PlaceDetails? _destLocation;

  Future<void> _createRide() async {
    if (_originLocation == null || _destLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid locations from the suggestions')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('rides').add({
        'driverId': user.uid,
        'origin': {
          'text': _originLocation!.formattedAddress,
          'lat': _originLocation!.lat,
          'lng': _originLocation!.lng
        },
        'destination': {
          'text': _destLocation!.formattedAddress,
          'lat': _destLocation!.lat,
          'lng': _destLocation!.lng
        },
        'departTime': FieldValue.serverTimestamp(),
        'seatsAvailable': int.tryParse(_seatsController.text) ?? 3,
        'farePerSeat': double.tryParse(_fareController.text) ?? 0,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Color(0xFF064E3B), Color(0xFF10B981)]
                  : [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildLocationField(
                      controller: _originController,
                      label: 'From',
                      icon: Icons.my_location,
                      onSuggestionSelected: (suggestion) async {
                        _originController.text = suggestion.description;
                        final details = await _placesService.getPlaceDetails(suggestion.placeId);
                        setState(() => _originLocation = details);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLocationField(
                      controller: _destController,
                      label: 'To',
                      icon: Icons.location_on,
                      onSuggestionSelected: (suggestion) async {
                        _destController.text = suggestion.description;
                        final details = await _placesService.getPlaceDetails(suggestion.placeId);
                        setState(() => _destLocation = details);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fareController,
                            decoration: InputDecoration(
                              labelText: 'Fare (₹)',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _seatsController,
                            decoration: InputDecoration(
                              labelText: 'Seats',
                              prefixIcon: const Icon(Icons.event_seat),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _createRide,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF059669) 
                        : const Color(0xFF11998e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text('Publish Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(PlaceSuggestion) onSuggestionSelected,
  }) {
    return TypeAheadField<PlaceSuggestion>(
      suggestionsCallback: (pattern) async {
        return await _placesService.getSuggestions(pattern);
      },
      builder: (context, controller, focusNode) {
        return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(suggestion.description),
        );
      },
      onSelected: onSuggestionSelected,
      errorBuilder: (context, error) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
    );
  }
}
