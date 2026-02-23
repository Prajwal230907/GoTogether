import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  num _totalEarnings = 0;
  int _totalRides = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Get all rides for this driver
      final ridesSnapshot = await FirebaseFirestore.instance.collection('rides')
          .where('driverId', isEqualTo: user.uid)
          .get();

      if (ridesSnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final rideIds = ridesSnapshot.docs.map((d) => d.id).toList();

      // 2. Get all confirmed/completed bookings for these rides
      final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings')
          .where('rideId', whereIn: rideIds)
          .where('bookingStatus', isEqualTo: 'completed') // Assuming completed means paid/done
          .get();

      num total = 0;
      int completedRides = 0;

      for (var doc in bookingsSnapshot.docs) {
        total += (doc.data()['amount'] as num?) ?? 0;
        completedRides++;
      }

      setState(() {
        _totalEarnings = total;
        _totalRides = completedRides;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching earnings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A120B) : const Color(0xFFF6F8F6);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = const Color(0xFF19E65E); // Green

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Earnings', style: GoogleFonts.publicSans(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: textColor),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        child: Column(
          children: [
            // Daily Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text('LIFETIME EARNINGS', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('₹$_totalEarnings', style: GoogleFonts.publicSans(fontSize: 48, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text('Great work!', style: GoogleFonts.publicSans(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('Hours', 'N/A', Icons.schedule, isDark, primaryColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Rides', '$_totalRides', Icons.directions_car, isDark, primaryColor, textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Tips', '₹0', Icons.payments, isDark, primaryColor, textColor)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Visual Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? primaryColor.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly Activity', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        Text('Total: ₹$_totalEarnings', style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 128,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildChartBar('M', 0.4, isDark, primaryColor),
                          _buildChartBar('T', 0.65, isDark, primaryColor),
                          _buildChartBar('W', 0.55, isDark, primaryColor),
                          _buildChartBar('T', 0.85, isDark, primaryColor, isSelected: true),
                          _buildChartBar('F', 0.3, isDark, primaryColor),
                          _buildChartBar('S', 0.95, isDark, primaryColor),
                          _buildChartBar('S', 0.2, isDark, primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Cash out button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.account_balance_wallet, color: Colors.black),
                label: Text('Cash Out Now', style: GoogleFonts.publicSans(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Rides
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Rides', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Text('See All', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRideItem('Downtown Terminal', '14:32 • 12.4 miles', '+\$18.50', 'Completed', Icons.local_taxi, isDark, primaryColor, textColor),
                  const SizedBox(height: 12),
                  _buildRideItem('Tip from Sarah', '14:10 • Ride #4829', '+\$5.00', 'Tip Received', Icons.volunteer_activism, isDark, primaryColor, textColor),
                  const SizedBox(height: 12),
                  _buildRideItem('Westside Plaza', '13:15 • 5.2 miles', '+\$12.20', 'Completed', Icons.local_taxi, isDark, primaryColor, textColor),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark, Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double fill, bool isDark, Color primaryColor, {bool isSelected = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: 12,
              height: 128 * fill - 20, // rough calculation
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : (isDark ? primaryColor.withOpacity(0.1) : Colors.grey[200]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10)] : [],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? primaryColor : Colors.grey)),
      ],
    );
  }

  Widget _buildRideItem(String title, String subtitle, String amount, String status, IconData icon, bool isDark, Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  Text(subtitle, style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: primaryColor)),
              Text(status, style: GoogleFonts.publicSans(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
