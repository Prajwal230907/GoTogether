import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Ride History', style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings')
            .where('passengerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No ride history found."));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingData = bookings[index].data() as Map<String, dynamic>;
              final rideId = bookingData['rideId'];
              final status = bookingData['bookingStatus'] as String? ?? 'Unknown';
              final createdAt = bookingData['createdAt'] as Timestamp?;
              final dateStr = createdAt != null 
                  ? DateFormat('MMM dd, hh:mm a').format(createdAt.toDate()) 
                  : 'Unknown Date';

              Color statusColor = Colors.grey;
              if (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed') statusColor = Colors.green;
              if (status.toLowerCase() == 'declined' || status.toLowerCase() == 'cancelled') statusColor = Colors.red;
              if (status.toLowerCase() == 'pending') statusColor = Colors.orange;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('rides').doc(rideId).get(),
                builder: (context, rideSnapshot) {
                  String title = 'Ride Context Unavailable';
                  if (rideSnapshot.hasData && rideSnapshot.data!.exists) {
                    final rideData = rideSnapshot.data!.data() as Map<String, dynamic>;
                    final dest = rideData['destination']?['text'] ?? 'Unknown location';
                    title = 'Ride to ${dest.split(',')[0]}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHistoryItem(context, title, dateStr, status, statusColor, primaryColor),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String title, String date, String status, Color statusColor, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_car, color: primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
