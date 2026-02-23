
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';

class ActiveRideScreen extends StatefulWidget {
  final String bookingId;

  const ActiveRideScreen({super.key, required this.bookingId});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  BookingModel? _booking;
  RideModel? _ride;
  UserModel? _driverInfo;
  UserModel? _passengerInfo;

  String _userRole = 'passenger';
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _driverCurrentLocation;
  
  // OTP Input Controllers
  final _otpController = TextEditingController();

  StreamSubscription<DocumentSnapshot>? _bookingSub;
  StreamSubscription<DocumentSnapshot>? _rideSub;

  @override
  void initState() {
    super.initState();
    _initDataflow();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _bookingSub?.cancel();
    _rideSub?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initDataflow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch own role
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
       _userRole = userDoc.data()?['role'] ?? 'passenger';
    }

    _bookingSub = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots().listen((bSnap) async {
       if (!bSnap.exists) return;
       
       final data = bSnap.data() as Map<String, dynamic>;
       final booking = BookingModel.fromMap(data, bSnap.id);
       
       if (mounted) setState(() => _booking = booking);

       // Setup ride listener if not already
       if (_ride == null) {
          _rideSub = FirebaseFirestore.instance.collection('rides').doc(booking.rideId).snapshots().listen((rSnap) async {
             if (!rSnap.exists) return;
             final ride = RideModel.fromMap(rSnap.data() as Map<String, dynamic>, rSnap.id);
             
             if (mounted) setState(() => _ride = ride);

             // Load Driver and Passenger profiles
             if (_driverInfo == null) {
               final dDoc = await FirebaseFirestore.instance.collection('users').doc(ride.driverId).get();
               if (dDoc.exists) _driverInfo = UserModel.fromMap(dDoc.data() as Map<String, dynamic>, dDoc.id);
             }
             if (_passengerInfo == null) {
               final pDoc = await FirebaseFirestore.instance.collection('users').doc(booking.passengerId).get();
               if (pDoc.exists) _passengerInfo = UserModel.fromMap(pDoc.data() as Map<String, dynamic>, pDoc.id);
             }

             if (mounted) setState(() {});

             _setupLocationTracking(ride.driverId);
          });
       }

       // Handle finish states
       if (booking.bookingStatus == 'completed' || booking.bookingStatus == 'cancelled') {
         if (mounted) context.go('/home'); // Or summary screen
       }
    });
  }

  void _setupLocationTracking(String driverId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.uid == driverId) {
      // I am the driver: Start tracking and pushing to firestore
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Initial push
      final pos = await Geolocator.getCurrentPosition();
      _pushDriverLocation(pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10)
      ).listen((Position position) {
        _pushDriverLocation(position);
        if (mounted) {
           setState(() => _driverCurrentLocation = LatLng(position.latitude, position.longitude));
           _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
        }
      });
    } else {
      // I am the passenger: listen to driver's location changes from Firestore User doc
      FirebaseFirestore.instance.collection('users').doc(driverId).snapshots().listen((doc) {
         if (doc.exists && doc.data() != null) {
            final loc = doc.data()!['driverLocation'];
            if (loc != null) {
               if (mounted) {
                 setState(() => _driverCurrentLocation = LatLng(loc['lat'], loc['lng']));
                 _mapController.move(LatLng(loc['lat'], loc['lng']), 15.0);
               }
            }
         }
      });
    }
  }

  Future<void> _pushDriverLocation(Position pos) async {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) return;
     await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'driverLocation': {'lat': pos.latitude, 'lng': pos.longitude}
     });
  }

  void _verifyOtpAndStart() async {
    if (_otpController.text != _booking?.otp) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
       return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'bookingStatus': 'in_progress',
        'startedAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('rides').doc(_ride!.id).update({
        'status': 'in_progress',
      });
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Started!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _completeRide() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'bookingStatus': 'completed',
        'completedAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('rides').doc(_ride!.id).update({
        'status': 'completed',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error completing ride: $e')));
    }
  }

  void _cancelRide() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'bookingStatus': 'cancelled',
      });
      if (_booking?.bookingStatus == 'confirmed') {
         await FirebaseFirestore.instance.collection('rides').doc(_ride!.id).update({
           'status': 'open',
         });
      } else {
         await FirebaseFirestore.instance.collection('rides').doc(_ride!.id).update({
           'status': 'cancelled',
         });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null || _ride == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    List<Marker> markers = [];
    
    // Add Route Polyline if available
    List<Polyline> polylines = [];
    if (_ride!.routePolyline != null && _ride!.routePolyline!.isNotEmpty) {
       final routePoints = _ride!.routePolyline!.map((p) => LatLng(p['lat'], p['lng'])).toList();
       polylines.add(Polyline(points: routePoints, color: primary, strokeWidth: 4.0));
    }

    // Add Pickup & Drop Markers
    if (_booking!.pickupLatLng != null) {
      markers.add(Marker(
        point: LatLng(_booking!.pickupLatLng!.lat, _booking!.pickupLatLng!.lng),
        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
      ));
    }
    if (_booking!.dropLatLng != null) {
      markers.add(Marker(
        point: LatLng(_booking!.dropLatLng!.lat, _booking!.dropLatLng!.lng),
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    // Driver Marker
    if (_driverCurrentLocation != null) {
      markers.add(Marker(
        point: _driverCurrentLocation!,
        child: Container(
           decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
           child: const Icon(Icons.directions_car, color: Colors.blue, size: 30),
        ),
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverCurrentLocation ?? const LatLng(12.9716, 77.5946),
              initialZoom: 15.0,
            ),
            children: [
               TileLayer(
                 urlTemplate: isDark 
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                 userAgentPackageName: 'com.example.mobile_flutter',
               ),
               PolylineLayer(polylines: polylines),
               MarkerLayer(markers: markers),
            ],
          ),

          // Top Header Overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white24, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
                  const SizedBox(width: 16),
                  Text(_booking!.bookingStatus == 'in_progress' ? 'Heading to Destination' : 'Driver En Route', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Bottom Sheet UI
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172336) : Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: _userRole == 'driver' ? _buildDriverUI() : _buildPassengerUI(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerUI() {
    final primary = AppColorsLight.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_booking!.bookingStatus == 'confirmed') ...[
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
             child: Column(
               children: [
                 const Text('SHARE OTP WITH DRIVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                 const SizedBox(height: 8),
                 if (_booking!.otp == null)
                    const Text('Legacy test ride: No OTP. Please cancel.', style: TextStyle(color: Colors.red, fontSize: 12))
                 else
                    Text(_booking!.otp!, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary, letterSpacing: 8)),
               ],
             ),
          ),
          const SizedBox(height: 24),
        ] else if (_booking!.bookingStatus == 'in_progress') ...[
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
             child: const Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.check_circle, color: Colors.green),
                 SizedBox(width: 8),
                 Text('Ride in progress...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
               ],
             ),
           ),
           const SizedBox(height: 24),
        ],
        
        Row(
          children: [
            CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${_driverInfo?.uid}'), backgroundColor: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_driverInfo?.name ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(_ride?.vehicleModel ?? 'Vehicle Specs', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            CircleAvatar(backgroundColor: primary.withOpacity(0.1), child: IconButton(icon: Icon(Icons.phone, color: primary), onPressed: (){})),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _cancelRide,
          child: const Text('Cancel Ride', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildDriverUI() {
    final primary = AppColorsLight.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${_passengerInfo?.uid}'), backgroundColor: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_passengerInfo?.name ?? 'Passenger', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(_booking?.seatsBooked.toString() ?? '1' ' Seat(s)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            CircleAvatar(backgroundColor: primary.withOpacity(0.1), child: IconButton(icon: Icon(Icons.phone, color: primary), onPressed: (){})),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_booking!.bookingStatus == 'confirmed')
           ElevatedButton(
              onPressed: () {
                 showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Text('Enter Code to Start Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 16),
                           TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 4,
                              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                           ),
                           const SizedBox(height: 16),
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                                onPressed: _verifyOtpAndStart,
                                style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                                child: const Text('VERIFY & START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             ),
                           ),
                           const SizedBox(height: 24),
                        ],
                      ),
                    );
                 });
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('ARRIVED - ENTER OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
           )
        else if (_booking!.bookingStatus == 'in_progress')
           ElevatedButton(
              onPressed: _completeRide,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('END RIDE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
           ),
           
        const SizedBox(height: 16),
        TextButton(
          onPressed: _cancelRide,
          child: const Text('Cancel Ride / Clear', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
