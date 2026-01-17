import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'create_ride_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isTripActive = false;
  
  void _startTrip() {
    setState(() => _isTripActive = true);
    // Simulate location updates
    Stream.periodic(const Duration(seconds: 5)).listen((_) async {
      if (!mounted || !_isTripActive) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Randomize slightly for demo
      final lat = 12.9716 + (DateTime.now().second * 0.0001);
      final lng = 77.5946 + (DateTime.now().second * 0.0001);

      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).collection('location').doc('current').set({
        'lat': lat,
        'lng': lng,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Location updated: $lat, $lng');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Color(0xFF064E3B), Color(0xFF10B981)] // Dark Green to Emerald
                  : [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Create Ride',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRideScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: _isTripActive ? 'Trip Active' : 'Start Trip',
                    icon: _isTripActive ? Icons.navigation : Icons.play_circle_outline,
                    color: _isTripActive ? Colors.orange : Colors.green,
                    onTap: _startTrip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isTripActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    const Text('Sharing live location...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
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
                    ? [Color(0xFF064E3B), Color(0xFF10B981)]
                    : [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text('driver@college.edu'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.drive_eta, size: 40, color: Color(0xFF11998e)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF11998e)),
            title: const Text('Settings'),
            onTap: () {
              context.push('/settings');
            },
          ),
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

  Widget _buildSummaryCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Color(0xFF064E3B), Color(0xFF047857)] // Darker Green
                : [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text('Today\'s Earnings', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('₹ 0.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('0', 'Rides'),
                Container(height: 40, width: 1, color: Colors.white24),
                _buildStat('0.0', 'Hours'),
                Container(height: 40, width: 1, color: Colors.white24),
                _buildStat('0', 'Km'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
