import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../data/models.dart';

class DriverRequestsScreen extends StatelessWidget {
  const DriverRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF120808) : const Color(0xFFF8F5F5);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = const Color(0xFFF20D0D);
    final acceptGreen = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // APP BAR AS BEFORE
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: acceptGreen, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Active Requests', style: GoogleFonts.inter(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Need to query bookings where rideId is mine, but Firestore doesn't support JOINs.
        // Easiest is to just query open rides for THIS driver, then for each ride, get bookings.
        // For simplicity in a single query, we can query rides where driverId == currentUserId AND status == 'open'.
        stream: FirebaseFirestore.instance.collection('rides')
            .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (context, ridesSnapshot) {
          if (!ridesSnapshot.hasData || ridesSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active rides or requests at the moment."));
          }

          final rideIds = ridesSnapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings')
                .where('rideId', whereIn: rideIds)
                .where('bookingStatus', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, bookingsSnapshot) {
              if (!bookingsSnapshot.hasData || bookingsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No pending passenger requests."));
              }

              final bookings = bookingsSnapshot.data!.docs;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final bookingData = bookings[index].data() as Map<String, dynamic>;
                  final bookingId = bookings[index].id;
                  
                  // Find the matching ride to get origin/dest details
                  final rideDoc = ridesSnapshot.data!.docs.firstWhere((doc) => doc.id == bookingData['rideId']);
                  final rideData = rideDoc.data() as Map<String, dynamic>;
                  
                  return _buildRequestCard(
                    context: context,
                    bookingId: bookingId,
                    amount: bookingData['amount'] ?? 0,
                    originText: rideData['origin']?['text'] ?? 'Pickup point',
                    destText: rideData['destination']?['text'] ?? 'Drop-off point',
                    passengerId: bookingData['passengerId'] ?? '',
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    acceptGreen: acceptGreen,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required String bookingId,
    required num amount,
    required String originText,
    required String destText,
    required String passengerId,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color acceptGreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1414) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey[200]!),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RIDE REQUEST', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('\$$amount', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                        Text('Est. Total Earning', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Route details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.radio_button_checked, color: primaryColor, size: 20),
                        Container(height: 40, width: 2, color: Colors.grey[300], margin: const EdgeInsets.symmetric(vertical: 4)),
                        const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PICKUP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(originText, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 20),
                          Text('DROP-OFF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(destText, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                // Retrieve actual passenger name
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(passengerId).get(),
                  builder: (context, snapshot) {
                    final name = (snapshot.hasData && snapshot.data!.exists) ? (snapshot.data!.data() as Map<String, dynamic>)['name'] : 'Passenger';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF160D0D) : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name ?? 'Passenger', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                              Text('Student', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus(context, bookingId, 'declined'),
                        icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
                        label: Text('Decline', style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus(context, bookingId, 'confirmed'),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: Text('Accept Ride', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: acceptGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, String bookingId, String status) async {
    try {
      final updates = <String, dynamic>{'bookingStatus': status};
      
      if (status == 'confirmed') {
        final random = Random();
        final otp = (1000 + random.nextInt(9000)).toString(); // 1000 to 9999
        updates['otp'] = otp;
        updates['acceptedAt'] = Timestamp.now();
      }

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(updates);
      
      if (context.mounted) {
         if (status == 'confirmed') {
            context.push('/active-ride', extra: bookingId);
         } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status!')));
         }
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
