import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as dart_ui;
import '../../theme/app_colors.dart';
import '../../maps/map_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _bikeIcon;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _determinePosition();
  }

  Future<void> _loadCustomMarkers() async {
    _carIcon = await _createMarkerImageFromIcon(Icons.directions_car, Colors.blue);
    _bikeIcon = await _createMarkerImageFromIcon(Icons.two_wheeler, Colors.orange);
    _addDummyDrivers();
  }

  Future<BitmapDescriptor> _createMarkerImageFromIcon(IconData iconData, Color color) async {
    final pictureRecorder = dart_ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    final textPainter = TextPainter(textDirection: dart_ui.TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);

    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        fontSize: 100.0,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = await image.toByteData(format: dart_ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _addDummyDrivers() {
    if (_carIcon == null || _bikeIcon == null) return;

    _markers.clear();
    // Simulating drivers
    _markers.add(Marker(
      markerId: const MarkerId('driver1'),
      position: const LatLng(12.9716, 77.5946),
      icon: _carIcon!, 
      infoWindow: const InfoWindow(title: 'Driver: John (Car)', snippet: '4 seats available'),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('driver2'),
      position: const LatLng(12.9750, 77.5980),
      icon: _bikeIcon!,
      infoWindow: const InfoWindow(title: 'Driver: Sarah (Bike)', snippet: '1 seat available'),
    ));
    setState(() {});
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _currentPosition = await Geolocator.getCurrentPosition();
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));
    }
    setState(() {});
  }

  void _centerMap() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      ));
    } else {
      _determinePosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Ride', style: TextStyle(fontWeight: FontWeight.bold)),
         flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [AppColorsDark.primaryGradientStart, AppColorsDark.primaryGradientEnd]
                  : [AppColorsLight.primaryGradientStart, AppColorsLight.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (Theme.of(context).brightness == Brightness.dark) {
                _mapController!.setMapStyle(darkMapStyle);
              } else {
                _mapController!.setMapStyle(null);
              }
              if (_currentPosition != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLng(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                ));
              }
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946), // Default to Bangalore
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We use custom button
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchBox(),
          ),
          Positioned(
            right: 16,
            bottom: 240, // Above the sheet
            child: FloatingActionButton(
              onPressed: _centerMap,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRideList(scrollController)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [AppColorsDark.primaryGradientStart, AppColorsDark.primaryGradientEnd]
                    : [AppColorsLight.primaryGradientStart, AppColorsLight.primaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text('student@college.edu'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF0072FF)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF0072FF)),
            title: const Text('My Bookings'),
            onTap: () {
              // Navigate to bookings
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF0072FF)),
            title: const Text('Profile'),
            onTap: () {
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF0072FF)),
            title: const Text('Settings'),
            onTap: () {
              context.push('/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.orange),
            title: const Text('Change Role'),
            onTap: () {
              context.go('/role_selection');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Where are you going?',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark 
              ? AppColorsDark.surfaceVariant 
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) {
          // Implement search filter
        },
      ),
    );
  }

  Widget _buildRideList(ScrollController scrollController) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('status', isEqualTo: 'open')
          .orderBy('departTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No rides available right now', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rideId = docs[index].id;
            final origin = data['origin']?['text'] ?? 'Unknown';
            final destination = data['destination']?['text'] ?? 'Unknown';
            final time = data['departTime'] != null 
                ? DateFormat('MMM d, h:mm a').format((data['departTime'] as Timestamp).toDate())
                : 'TBD';
            final fare = data['farePerSeat'] ?? 0;
            final seats = data['seatsAvailable'] ?? 0;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _showBookingDialog(context, rideId, fare),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.circle, size: 12, color: Colors.blue),
                              Container(height: 24, width: 2, color: Colors.grey[300]),
                              const Icon(Icons.location_on, size: 12, color: Colors.red),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(origin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 16),
                                Text(destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹$fare', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 4),
                              Text('$seats seats', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(time, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const Text('View Details', style: TextStyle(color: Color(0xFF0072FF), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingDialog(BuildContext context, String rideId, num fare) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm Booking'),
      content: Text('Book this ride for ₹$fare?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0072FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            Navigator.pop(context);
            await _bookRide(rideId, fare);
          },
          child: const Text('Book Ride'),
        ),
      ],
    ));
  }

  Future<void> _bookRide(String rideId, num fare) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'rideId': rideId,
        'passengerId': user.uid,
        'seatsBooked': 1,
        'amount': fare,
        'paymentStatus': 'pending',
        'bookingStatus': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
