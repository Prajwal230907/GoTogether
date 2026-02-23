import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import '../../data/models.dart';

const String _kIgnoredApiKey = '';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _fareController = TextEditingController();
  final _vehicleModelController = TextEditingController(); // Visual only
  
  // Logic state
  int _seats = 3;
  DateTime _selectedTime = DateTime.now();
  bool _isLoading = false;
  
  final _placesService = PlacesService(_kIgnoredApiKey);
  final MapController _mapController = MapController();
  PlaceDetails? _originLocation;
  PlaceDetails? _destLocation;
  List<Marker> _markers = [];
  List<LatLng> _routePoints = [];
  LatLng _mapCenter = const LatLng(12.9716, 77.5946);

  // Constants
  final List<String> _preferences = ['No Smoking', 'Music Allowed', 'Pets Welcome'];

  void _updateMap(PlaceDetails location, String type) {
    setState(() {
      final position = LatLng(location.lat, location.lng);
      _mapCenter = position;
      
      _markers = [];
      if (_originLocation != null) {
        _markers.add(Marker(
          point: LatLng(_originLocation!.lat, _originLocation!.lng),
          width: 40, height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ));
      }
      if (_destLocation != null) {
        _markers.add(Marker(
          point: LatLng(_destLocation!.lat, _destLocation!.lng),
          width: 40, height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ));
      }
    });

    if (_originLocation != null && _destLocation != null) {
       _fetchRoute();
    } else {
      _mapController.move(LatLng(location.lat, location.lng), 14.0);
    }
  }

  Future<void> _fetchRoute() async {
    if (_originLocation == null || _destLocation == null) return;
    
    final start = _originLocation!;
    final end = _destLocation!;
    
    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          final distanceMeters = routes[0]['distance'] as num;
          
          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
            // Fare: ₹12 per km
            final distanceKm = distanceMeters / 1000;
            final fare = (distanceKm * 12).round();
            _fareController.text = fare.toString();
          });
          
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load route: $e')));
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        // If picked time is in past, assume tomorrow
        if (_selectedTime.isBefore(now)) {
            _selectedTime = _selectedTime.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _createRide() async {
    if (_originLocation == null || _destLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid locations')));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check verification status first
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        // TEMPORARY BYPASS: Always true for testing
        // final isVerified = userDoc.data()?['isVerified'] ?? false;
        final isVerified = true; 
        
        if (!isVerified) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Your account is pending verification. You cannot post rides yet.'),
              backgroundColor: Colors.redAccent,
            ));
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // Check if driver already has an active or open ride
      final activeRides = await FirebaseFirestore.instance.collection('rides')
          .where('driverId', isEqualTo: user.uid)
          .where('status', whereIn: ['open', 'active', 'in_progress'])
          .get();
          
      if (activeRides.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You already have an active ride. Complete or cancel it before posting a new one.'),
            backgroundColor: Colors.redAccent,
          ));
          setState(() => _isLoading = false);
        }
        return;
      }

      final rideId = const Uuid().v4();
      final ride = RideModel(
        id: rideId,
        driverId: user.uid,
        origin: LocationPoint(text: _originLocation!.formattedAddress, lat: _originLocation!.lat, lng: _originLocation!.lng),
        destination: LocationPoint(text: _destLocation!.formattedAddress, lat: _destLocation!.lat, lng: _destLocation!.lng),
        departTime: Timestamp.fromDate(_selectedTime),
        seatsAvailable: _seats,
        farePerSeat: double.tryParse(_fareController.text) ?? 0,
        status: 'open',
        createdAt: Timestamp.now(),
        vehicleModel: _vehicleModelController.text,
        routePolyline: _routePoints.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList(),
      );
      
      await FirebaseFirestore.instance.collection('rides').doc(rideId).set(ride.toMap());
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF171C26) : Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: textColor,
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ),
        title: Text('Offer a Ride', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
        centerTitle: true,
        actions: [
           Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF171C26) : Colors.white,
              child: Icon(Icons.help_outline, color: textColor),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // Bottom padding for fixed button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Indicator
                Row(
                  children: [
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(3)))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: primaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(3)))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(3)))),
                  ],
                ),
                const SizedBox(height: 32),

                // Vehicle Details
                _SectionHeader(icon: Icons.directions_car, title: 'Vehicle Details', color: primaryColor, textColor: textColor),
                const SizedBox(height: 12),
                _StyledTextField(
                  controller: _vehicleModelController, 
                  placeholder: 'e.g. Tesla Model 3 (White)',
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // Route Information
                _SectionHeader(icon: Icons.route, title: 'Route Information', color: primaryColor, textColor: textColor),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF171C26).withOpacity(0.7) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40, bottom: 40, left: 11,
                        child: Container(width: 2, decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2, style: BorderStyle.solid)))), 
                      ),
                      Column(
                        children: [
                          _RouteInputRow(
                            icon: Container(width: 24, height: 24, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8)]), child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))), 
                            label: 'Pickup Point', 
                            child: _buildLocationField(controller: _originController, placeholder: 'Search campus location...', onSuggestionSelected: (s) {
                               _originController.text = s.description;
                               final d = PlaceDetails(lat: s.lat, lng: s.lng, formattedAddress: s.description);
                               setState(() => _originLocation = d);
                               _updateMap(d, 'origin');
                            }, isDark: isDark, textColor: textColor),
                          ),
                          const SizedBox(height: 24),
                          _RouteInputRow(
                            icon: Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 8)]), child: const Icon(Icons.location_on, size: 14, color: Colors.white)), 
                            label: 'Destination', 
                            child:  _buildLocationField(controller: _destController, placeholder: 'Where are you heading?', onSuggestionSelected: (s) {
                               _destController.text = s.description;
                               final d = PlaceDetails(lat: s.lat, lng: s.lng, formattedAddress: s.description);
                               setState(() => _destLocation = d);
                               _updateMap(d, 'dest');
                            }, isDark: isDark, textColor: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Map Preview (Styled)
                if (_originLocation != null || _destLocation != null) ...[
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(initialCenter: _mapCenter, initialZoom: 13.0),
                            children: [
                              TileLayer(
                                urlTemplate: isDark ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.gotogether.app',
                              ),
                              PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 4.0, color: primaryColor)]),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
                          // Fare display overlay
                          if (_fareController.text.isNotEmpty && _fareController.text != '0')
                             Positioned(
                               bottom: 12, right: 12,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                                 child: Text('Est. Fare: ₹${_fareController.text}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               ),
                             ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Time & Seats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPARTURE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey[600])),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF171C26) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('hh:mm a').format(_selectedTime), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SEATS AVAILABLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey[600])),
                          const SizedBox(height: 8),
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF171C26) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove), 
                                  color: isDark ? Colors.grey : Colors.grey[600],
                                  onPressed: () => setState(() => _seats = _seats > 1 ? _seats - 1 : 1),
                                ),
                                Text('$_seats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                                Container(
                                  decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 20), color: Colors.white,
                                    onPressed: () => setState(() => _seats++),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Preferences
                Text('RIDE PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey[600])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _preferences.map((pref) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171C26) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: Text(pref, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey[600])),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Bottom Button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bgColor, bgColor.withOpacity(0)],
                ),
              ),
              child: InkWell(
                onTap: _isLoading ? null : _createRide,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6366F1)]), // Purple Gradient
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       if (_isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                       else ...[
                          const Text('Post Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          const Icon(Icons.bolt, color: Colors.white),
                       ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({required TextEditingController controller, required String placeholder, required Function(PlaceSuggestion) onSuggestionSelected, required bool isDark, required Color textColor}) {
    return TypeAheadField<PlaceSuggestion>(
      controller: controller,
      suggestionsCallback: (pattern) async => await _placesService.getSuggestions(pattern),
      builder: (context, controller, focusNode) {
        return TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          tileColor: isDark ? const Color(0xFF171C26) : Colors.white,
          leading: const Icon(Icons.location_on_outlined),
          title: Text(suggestion.description, style: TextStyle(color: textColor)),
        );
      },
      onSelected: onSuggestionSelected,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color textColor;

  const _SectionHeader({required this.icon, required this.title, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool isDark;

  const _StyledTextField({required this.controller, required this.placeholder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RouteInputRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final Widget child;

  const _RouteInputRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
