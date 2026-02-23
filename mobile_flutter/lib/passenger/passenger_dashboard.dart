import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as dart_ui;
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../data/models.dart';
import 'package:uuid/uuid.dart';
import '../../services/places_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PassengerDashboard extends ConsumerStatefulWidget {
  const PassengerDashboard({super.key});

  @override
  ConsumerState<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends ConsumerState<PassengerDashboard> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _activeBookingSub;
  final List<Marker> _markers = [];
  bool _isNavigatingToActiveRide = false;
  String _userRole = 'passenger';
  bool _isBike = false;
  bool _isAdmin = false;

  final _placesService = PlacesService(''); // API key ignored by the service implementation
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  PlaceDetails? _pickupLocation;
  PlaceDetails? _dropLocation;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _startListeningToLocation();
    _listenForActiveBooking();
  }

  void _listenForActiveBooking() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _activeBookingSub = FirebaseFirestore.instance.collection('bookings')
        .where('passengerId', isEqualTo: user.uid)
        .where('bookingStatus', whereIn: ['confirmed', 'in_progress'])
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty && !_isNavigatingToActiveRide) {
        final bookingId = snap.docs.first.id;
        _isNavigatingToActiveRide = true;
        if (mounted) {
           context.push('/active-ride', extra: bookingId).then((_) {
              _isNavigatingToActiveRide = false; // reset when popped
           });
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _activeBookingSub?.cancel();
    super.dispose();
  }

  // --- Map & Data Logic (Preserved) ---
  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRole = data['role'] ?? 'passenger';
          _isAdmin = data['role'] == 'admin' || data['isAdmin'] == true;
          final vehicleModel = (data['vehicleModel'] ?? '').toString().toLowerCase();
          _isBike = vehicleModel.contains('bike') || vehicleModel.contains('scooter') || vehicleModel.contains('motorcycle');
          if (_currentPosition != null) {
            _updateUserMarker(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
          }
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  void _updateUserMarker(LatLng point) {
    _markers.removeWhere((m) => m.key == const Key('user_location'));
    IconData iconData;
    Color color;

    if (_userRole == 'driver') {
      // Passenger shouldn't be rendering drivers based on themselves, but maybe nearby drivers.
      iconData = Icons.directions_car;
      color = Colors.blue; 
    } else {
      iconData = Icons.person_pin_circle;
      color = Colors.red;
    }
    
    _markers.add(Marker(
      key: const Key('user_location'),
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Icon(iconData, color: color, size: 30),
      ),
    ));
  }

  Future<void> _startListeningToLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _updateUserMarker(LatLng(position.latitude, position.longitude));
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    }

    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _updateUserMarker(LatLng(position.latitude, position.longitude));
        });
      }
    });
  }

  Future<void> _bookRide(String rideId, num fare) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final bookingId = const Uuid().v4();
      final booking = BookingModel(
        id: bookingId,
        rideId: rideId,
        passengerId: user.uid,
        seatsBooked: 1,
        amount: fare,
        paymentStatus: 'pending',
        bookingStatus: 'pending', // Passenger requests are pending driver approval
        createdAt: Timestamp.now(),
      );

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set(booking.toMap());
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to driver!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Map Background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(12.9716, 77.5946),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark 
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' // Dark Map
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Light Map
                  userAgentPackageName: 'com.example.mobile_flutter',
                ),
                 MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // Map Gradient Overlay for Readability (Bottom Up)
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? AppColorsDark.background : AppColorsLight.background).withOpacity(0.8),
                    (isDark ? AppColorsDark.background : AppColorsLight.background),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColorsLight.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColorsLight.primary.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.school, color: AppColorsLight.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GoTogether',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'CAMPUS EXCLUSIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColorsLight.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_isAdmin)
                          _GlassIconButton(
                            icon: Icons.admin_panel_settings,
                            onTap: () => context.push('/admin'),
                          ),
                        if (_isAdmin)
                          const SizedBox(width: 8),
                        _GlassIconButton(icon: Icons.notifications_none, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Search Bar Area
          Positioned(
            top: 100,
            left: 24,
            right: 24,
            child: _GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   _buildLocationField(
                      controller: _pickupController, 
                      placeholder: 'Current Location', 
                      icon: Icons.my_location,
                      onSuggestionSelected: (s) {
                        _pickupController.text = s.description;
                        setState(() => _pickupLocation = PlaceDetails(lat: s.lat, lng: s.lng, formattedAddress: s.description));
                        if (_pickupLocation != null) _updateUserMarker(LatLng(_pickupLocation!.lat, _pickupLocation!.lng));
                      },
                      isDark: isDark,
                   ),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                   _buildLocationField(
                      controller: _dropController, 
                      placeholder: 'Where to?', 
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      onSuggestionSelected: (s) {
                        _dropController.text = s.description;
                        setState(() => _dropLocation = PlaceDetails(lat: s.lat, lng: s.lng, formattedAddress: s.description));
                      },
                      isDark: isDark,
                   ),
                ],
              ),
            ),
          ),

          // 4. Content (Nearby Rides Carousel) + Buttons
          Positioned(
            bottom: 100, // Space for Bottom Nav
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColorsLight.primary, Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(color: AppColorsLight.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_pickupLocation == null) {
                                  // Fallback to current location if tracking
                                  if (_currentPosition != null) {
                                     _pickupLocation = PlaceDetails(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude, formattedAddress: 'Current Location');
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pickup location')));
                                     return;
                                  }
                                }
                                if (_dropLocation == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination')));
                                   return;
                                }
                                
                                context.push('/ride-search', extra: {
                                  'pickup': _pickupLocation,
                                  'drop': _dropLocation,
                                });
                              },
                              borderRadius: BorderRadius.circular(28),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Find Rides',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nearby Rides Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Rides',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/ride-search'), // View All logic
                        child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Carousel
                SizedBox(
                  height: 140,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('rides').where('status', isEqualTo: 'open').limit(5).snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                         return Center(child: Text("No rides nearby.", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
                      }
                      
                      // Keep markers updated with active rides
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          // keep user marker, clear others
                          _markers.removeWhere((m) => m.key != const Key('user_location'));
                          for (var doc in docs) {
                             try {
                               final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                               _markers.add(Marker(
                                  point: LatLng(ride.origin.lat, ride.origin.lng),
                                  width: 40, height: 40,
                                  child: const Icon(Icons.directions_car, color: Colors.blue, size: 40),
                               ));
                             } catch (e) {}
                          }
                        });
                      });

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final ride = RideModel.fromMap(data, docs[index].id);
                          return _RideCard(
                            ride: ride, 
                            onTap: () => _showBookingDialog(context, ride.id, ride.farePerSeat),
                            isDark: isDark,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 5. Custom Bottom Nav
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _CustomBottomNav(
              onTap: (index) {
                if (index == 4) context.push('/profile'); // Profile
                if (index == 1) context.push('/ride-history'); // Trips
                if (index == 2) context.push('/create-ride'); // Add/Offer
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String rideId, num fare) {
      // Existing booking dialog logic
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Booking'),
        content: Text('Book this ride for ₹$fare?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bookRide(rideId, fare);
            },
            child: const Text('Book Ride'),
          ),
        ],
      ));
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    Color? iconColor,
    required void Function(PlaceSuggestion) onSuggestionSelected,
    required bool isDark,
  }) {
    return TypeAheadField<PlaceSuggestion>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            prefixIcon: Icon(icon, color: iconColor ?? AppColorsLight.primary),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        if (pattern.length < 3) return [];
        return await _placesService.getSuggestions(pattern);
      },
      itemBuilder: (context, PlaceSuggestion suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on, color: Colors.grey),
          title: Text(suggestion.description, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        );
      },
      onSelected: onSuggestionSelected,
    );
  }
}

// --- Helper Widgets ---

class _GlassContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassContainer({this.height, this.width, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF172336).withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: _GlassContainer(
        height: 40, width: 40,
        child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColorsLight.primary.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: isDark ? const Color(0xFF172336).withOpacity(0.6) : Colors.white.withOpacity(0.6),
            child: InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColorsLight.primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onTap;
  final bool isDark;

  const _RideCard({required this.ride, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // In a full app, we would query the user's name/photo using ride.driverId.
    // Given the constraints and the UI requirements, we simulate the display logic here:
    final name = 'Driver'; 
    final vehicle = ride.vehicleModel?.isNotEmpty == true ? ride.vehicleModel! : 'Compact Car'; 
    final fare = ride.farePerSeat;
    final destination = ride.destination.text;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/100'), // Placeholder
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text(vehicle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('NEARBY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColorsLight.primary)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text("To ${destination.split(',')[0]}", style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Text('₹$fare', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  final Function(int) onTap;

  const _CustomBottomNav({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172336).withOpacity(0.9) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.home, label: 'Home', isSelected: true, onTap: () => onTap(0), isDark: isDark),
          _NavItem(icon: Icons.directions_car, label: 'Trips', isSelected: false, onTap: () => onTap(1), isDark: isDark),
          
          // Center Placeholder to keep spacing or removed entirely. Let's reshape it without center add button since passengers only book.
          
          _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat', isSelected: false, onTap: () => onTap(3), isDark: isDark),
          _NavItem(icon: Icons.person_outline, label: 'Profile', isSelected: false, onTap: () => onTap(4), isDark: isDark),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppColorsLight.primary : (isDark ? Colors.white54 : Colors.grey), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppColorsLight.primary : (isDark ? Colors.white54 : Colors.grey))),
        ],
      ),
    );
  }
}
