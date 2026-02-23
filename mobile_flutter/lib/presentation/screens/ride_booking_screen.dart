import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../data/models.dart';
import '../../services/places_service.dart';
import 'package:geolocator/geolocator.dart'; // for distance calculation

class RideBookingScreen extends StatefulWidget {
  final RideModel? ride;
  final int? fare;
  final PlaceDetails? pickup;
  final PlaceDetails? drop;

  const RideBookingScreen({super.key, this.ride, this.fare, this.pickup, this.drop});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  int _selectedSeat = 1;
  late double _baseFare;
  final double _discount = 0.0;
  List<LatLng> _routePoints = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _baseFare = (widget.fare ?? 0).toDouble();

    if (widget.ride?.routePolyline != null) {
      _routePoints = widget.ride!.routePolyline!
          .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList();
    }
  }

  Future<void> _createBooking() async {
    if (widget.ride == null) return;
    
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if the passenger already has a confirmed or in_progress booking
      final activeBookings = await FirebaseFirestore.instance.collection('bookings')
          .where('passengerId', isEqualTo: user.uid)
          .where('bookingStatus', whereIn: ['confirmed', 'in_progress'])
          .get();
          
      if (activeBookings.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You already have an active or confirmed ride. Complete it before requesting a new one.'),
            backgroundColor: Colors.redAccent,
          ));
          setState(() => _isLoading = false);
        }
        return;
      }

      final bookingId = const Uuid().v4();
      
      double? distanceKm;
      if (widget.pickup != null && widget.drop != null) {
        distanceKm = Geolocator.distanceBetween(widget.pickup!.lat, widget.pickup!.lng, widget.drop!.lat, widget.drop!.lng) / 1000;
      }

      final booking = BookingModel(
        id: bookingId,
        rideId: widget.ride!.id,
        passengerId: user.uid,
        seatsBooked: _selectedSeat,
        amount: (_baseFare * _selectedSeat) - _discount,
        paymentStatus: 'pending',
        bookingStatus: 'pending',
        createdAt: Timestamp.now(),
        pickupLatLng: widget.pickup != null ? LocationPoint(text: widget.pickup!.formattedAddress, lat: widget.pickup!.lat, lng: widget.pickup!.lng) : null,
        dropLatLng: widget.drop != null ? LocationPoint(text: widget.drop!.formattedAddress, lat: widget.drop!.lat, lng: widget.drop!.lng) : null,
        distanceKm: distanceKm,
      );

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set(booking.toMap());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed! Request sent to driver.')));
        context.go('/home'); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ride == null) {
       return const Scaffold(body: Center(child: Text("Invalid Ride Data")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty ? _routePoints.first : const LatLng(37.4275, -122.1697),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark 
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' 
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.cyanAccent,
                    ),
                  ],
                ),
            ],
          ),
          
          // Header Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   CircleAvatar(
                     backgroundColor: Colors.black54,
                     child: IconButton(
                       icon: const Icon(Icons.arrow_back, color: Colors.white),
                       onPressed: () => context.pop(),
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                     child: const Text('Ride Confirmation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                   const CircleAvatar(
                     backgroundColor: Colors.black54,
                     child: Icon(Icons.more_vert, color: Colors.white),
                   ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172336).withOpacity(0.9) : Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Pull Handle
                   Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 20))),

                   // Driver Info
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Row(
                           children: [
                             Stack(
                               children: [
                                  CircleAvatar(backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=Driver'), radius: 24),
                                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4)), child: const Text('4.9', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                               ],
                             ),
                             const SizedBox(width: 12),
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                 Text('${widget.ride!.vehicleModel ?? "Car"}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                               ],
                             ),
                           ],
                         ),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text('GO-2GETHR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor))),
                             const SizedBox(height: 4),
                             const Text('PLATE NUMBER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                           ],
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),

                   // Seat Selection
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('SELECT SEATS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                       Text('Max 4 passengers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.start,
                     children: [1, 2, 3, 4].map((seats) {
                       final isSelected = _selectedSeat == seats;
                       if (seats > widget.ride!.seatsAvailable) {
                          return Expanded(child: SizedBox()); // hide unavailable seats
                       }
                       return Expanded(
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 4.0),
                           child: InkWell(
                             onTap: () => setState(() => _selectedSeat = seats),
                             child: Container(
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               decoration: BoxDecoration(
                                 color: isSelected ? primaryColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.black12)),
                               ),
                               child: Column(
                                 children: [
                                   Text('$seats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
                                   Text(seats == 1 ? 'SEAT' : 'SEATS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey)),
                                 ],
                               ),
                             ),
                           ),
                         ),
                       );
                     }).toList(),
                   ),
                   const SizedBox(height: 24),

                   // Fare Breakdown
                   _buildFareRow('Base Fare', '₹${(_baseFare * _selectedSeat).toStringAsFixed(2)}', textColor),
                   const SizedBox(height: 8),
                   _buildFareRow('Student Discount (0%)', '-₹${_discount.toStringAsFixed(2)}', Colors.cyanAccent, icon: Icons.verified),
                   const Divider(height: 24),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('TOTAL ESTIMATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                           Text('₹${((_baseFare * _selectedSeat) - _discount).toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                         ],
                       ),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           const Text('PAYMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                           Row(
                             children: [
                               Icon(Icons.account_balance_wallet, size: 16, color: primaryColor),
                               const SizedBox(width: 4),
                               Text('Cash on Drop', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                             ],
                           ),
                         ],
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),

                   // Confirm Button
                   ElevatedButton(
                     onPressed: _isLoading ? null : _createBooking,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: primaryColor,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                       textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                     ),
                     child: _isLoading 
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)))
                        : Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Text('Confirm Booking'),
                           const SizedBox(width: 8),
                           const Icon(Icons.arrow_forward),
                         ],
                       ),
                   ),
                   const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value, Color color, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
            Text(label, style: TextStyle(color: color == Colors.cyanAccent ? color : Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
