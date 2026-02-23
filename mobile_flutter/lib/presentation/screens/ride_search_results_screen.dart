import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/places_service.dart';
import '../../data/models.dart';
import 'package:geolocator/geolocator.dart'; // for distance calculation

class RideSearchResultsScreen extends StatefulWidget {
  final PlaceDetails? pickup;
  final PlaceDetails? drop;

  const RideSearchResultsScreen({super.key, this.pickup, this.drop});

  @override
  State<RideSearchResultsScreen> createState() => _RideSearchResultsScreenState();
}

class _RideSearchResultsScreenState extends State<RideSearchResultsScreen> {
  // Proximity buffer for matching route (in meters)
  static const double _routeProximityMeters = 1000.0;

  bool _isMatch(RideModel ride) {
    if (widget.pickup == null || widget.drop == null) return true;
    if (ride.routePolyline == null || ride.routePolyline!.isEmpty) return false;

    int pickupIndex = -1;
    int dropIndex = -1;
    double minPickupDist = double.infinity;
    double minDropDist = double.infinity;

    for (int i = 0; i < ride.routePolyline!.length; i++) {
       final point = ride.routePolyline![i];
       final lat = point['lat'] as double;
       final lng = point['lng'] as double;

       double pDist = Geolocator.distanceBetween(widget.pickup!.lat, widget.pickup!.lng, lat, lng);
       if (pDist < _routeProximityMeters && pDist < minPickupDist) {
         minPickupDist = pDist;
         pickupIndex = i;
       }

       double dDist = Geolocator.distanceBetween(widget.drop!.lat, widget.drop!.lng, lat, lng);
       if (dDist < _routeProximityMeters && dDist < minDropDist) {
         minDropDist = dDist;
         dropIndex = i;
       }
    }

    // Direction Match Check: Pickup must be along the route before the drop
    if (pickupIndex != -1 && dropIndex != -1 && pickupIndex < dropIndex) {
       return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    // Display title
    String searchTitle = 'Search Results';
    if (widget.pickup != null && widget.drop != null) {
      searchTitle = '${widget.pickup!.formattedAddress.split(',')[0]} → ${widget.drop!.formattedAddress.split(',')[0]}';
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              // Glassmorphism effect handled by color opacity or blur if using Stack/BackdropFilter
              // keeping simple for now matching logic structure
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF172336).withOpacity(0.8) : Colors.white.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Search Results', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(searchTitle, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: textColor), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        child: Icon(Icons.tune, color: textColor), // Filter icon
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(context, 'Time', true, primaryColor, textColor),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'Price', false, primaryColor, textColor),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'Vehicle', false, primaryColor, textColor),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'Verified Only', false, primaryColor, textColor, hasArrow: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rides').where('status', isEqualTo: 'open').where('seatsAvailable', isGreaterThan: 0).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Error loading rides'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Filter by route overlap logic
                  final matchedRides = docs.map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                                           .where((ride) => _isMatch(ride)).toList();

                  if (matchedRides.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text("No rides found along this route.\nTry expanding your search.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: matchedRides.length + 1, // +1 for Map Hint
                    itemBuilder: (context, index) {
                      if (index == matchedRides.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildMapHint(context),
                        );
                      }
                      
                      final ride = matchedRides[index];
                      // Use fare from the ride model
                      final fare = ride.farePerSeat.toInt();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRideCard(context, ride, fare, 'Driver Name', '4.9', '${ride.vehicleModel ?? 'Car'}', 'ETA'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, Color primary, Color textColor, {bool hasArrow = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primary : (isDark ? Colors.white10 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
          if (hasArrow) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: isSelected ? Colors.white : Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, RideModel ride, int fare, String name, String rating, String car, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final primary = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?u=$name'), fit: BoxFit.cover),
                      border: Border.all(color: primary.withOpacity(0.3), width: 2),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                      child: const Icon(Icons.verified, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(rating, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹$fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primary)),
                  const Text('PER SEAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Column(
                     children: [
                       Icon(Icons.directions_car, color: primary),
                       const SizedBox(height: 4),
                       Text(car, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(width: 16),
                   Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Arrives in', style: TextStyle(fontSize: 10, color: Colors.grey)),
                       Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary)),
                     ],
                   ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                   context.push('/ride-booking', extra: {
                     'ride': ride,
                     'fare': fare,
                     'pickup': widget.pickup,
                     'drop': widget.drop,
                   });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Book Seat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapHint(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
           image: NetworkImage('https://tile.openstreetmap.org/12/2621/1706.png'), // Placeholder map tile
           fit: BoxFit.cover,
           opacity: 0.6,
        ),
      ),
      child: Stack(
        children: [
          Container(
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(20),
               gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
             ),
          ),
          const Positioned(
            bottom: 16, left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ROUTE OVERVIEW', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                Text('3.4 miles • ~15 mins total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: const Icon(Icons.map, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
