import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  bool _isTripActive = false;
  bool _isAdmin = false;
  StreamSubscription? _locationStream;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _isAdmin = data['role'] == 'admin' || data['isAdmin'] == true;
          });
        }
      }
    } catch (e) {
      print('Error fetching driver profile: $e');
    }
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    super.dispose();
  }

  void _toggleOnlineState(bool value) {
    setState(() => _isTripActive = value);
    if (_isTripActive) {
      // Simulate location updates
      _locationStream = Stream.periodic(const Duration(seconds: 5)).listen((_) async {
        if (!mounted || !_isTripActive) return;
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        
        final lat = 12.9716 + (DateTime.now().second * 0.0001);
        final lng = 77.5946 + (DateTime.now().second * 0.0001);

        await FirebaseFirestore.instance.collection('drivers').doc(user.uid).collection('location').doc('current').set({
          'lat': lat,
          'lng': lng,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } else {
      _locationStream?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF191022) : const Color(0xFFF7F6F8);
    final textColor = isDark ? Colors.white : const Color(0xFF0F1723);
    final primaryColor = const Color(0xFF7F13EC); // Stitch driver primary

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above the bottom nav
        child: FloatingActionButton.extended(
          onPressed: () {
             context.push('/create-ride');
          },
          backgroundColor: primaryColor,
          elevation: 4,
          icon: const Icon(Icons.add_circle, color: Colors.white),
          label: Text('Publish Ride', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark, primaryColor, textColor),
                _buildStatusSection(isDark, primaryColor, textColor),
                _buildQuickStats(isDark, primaryColor, textColor),
                Expanded(child: _buildMapSection(isDark, primaryColor, textColor)),
                const SizedBox(height: 90), // Spacing for bottom nav
              ],
            ),
            
            // Floating Bottom Nav
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _buildBottomNav(isDark, primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, Color textColor) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? 'Alex Rivera';

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAEqYPvSQ3TK57gc2iVcfj_cojPmVr81kL8pOFxIYEWVFwpdnDDusXf-vOap2_By_J6txZ09ECH3dcjyNKFbNxbLnkiqo21d9yy8dUtmSlJKIizZrwXvrkwKzX8YeYoKbX1114REl33MVhrUXwLYwnH65PSmuaix5xOncB_RtOOEKpF0WITHalBKzsfaf4ECZZWfssdh_oQqeocdyMvUL7nTVxO_1hOrttPRDhN3q-eAJCmGudjZXNgbHj8AgD_A_jYqi1hDqcqKRQ',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  Text(name, style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                  onPressed: () => context.push('/admin'),
                ),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications, color: isDark ? primaryColor : Colors.grey[700], size: 20),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF191022) : const Color(0xFFF7F6F8), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isDark, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
          boxShadow: [
            if (!isDark) BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
            if (isDark) BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Go Online', style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text('Ready to pick up students?', style: GoogleFonts.publicSans(fontSize: 14, color: Colors.grey)),
              ],
            ),
            Switch(
              value: _isTripActive,
              onChanged: _toggleOnlineState,
              activeColor: Colors.white,
              activeTrackColor: primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: isDark ? primaryColor.withOpacity(0.2) : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, Color primaryColor, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Hours', '4.2h', Icons.schedule, isDark, primaryColor, textColor),
          const SizedBox(width: 16),
          _buildStatCard('Earnings', '\$84.50', Icons.payments, isDark, primaryColor, textColor),
          const SizedBox(width: 16),
          _buildStatCard('Rating', '4.9', Icons.stars, isDark, primaryColor, textColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark, Color primaryColor, Color textColor) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildMapSection(bool isDark, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hot Zones Near You', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('HIGH DEMAND', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Mock Map Background
                  Positioned.fill(
                    child: ColorFiltered(
                      colorFilter: isDark 
                          ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
                          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDpGXc_wrWPq5nyoYlOxMXUsidrgYq4akJNuVsCe49MH_Xex2w-j9gu8rd-k0w78pQCUkEE6wzT-kCFj861tcIxeYQrToo5Ly-1rS3otgkodLPzETtyrB4Z79hzBFTlaDzafOpI0i0Xz1ivrgJBiJdn37WFT_Ft-8ObCyJZBe68T7gAqo32KSKlaJQTUSly9Pd6MurIXeVhBLSBZB5kFgGUT7klwhk1wIdmFp-p79T_BDwFpsa51JG2YN8Ztqc5te-8MmEjRNVSkpA',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: isDark ? Colors.grey[900] : Colors.grey[300]),
                      ),
                    ),
                  ),
                  
                  // Heatmap overlays
                  Positioned(
                    top: 50, left: 60,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [primaryColor.withOpacity(0.4), primaryColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80, right: 40,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [primaryColor.withOpacity(0.5), primaryColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),

                  // Driver Marker
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF191022) : Colors.white, width: 4),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF191022) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Text('YOU', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                      ],
                    ),
                  ),

                  // Floating Map Controls
                  Positioned(
                    top: 16, right: 16,
                    child: Column(
                      children: [
                        _buildMapButton(Icons.layers, isDark, textColor),
                        const SizedBox(height: 8),
                        _buildMapButton(Icons.my_location, isDark, textColor),
                      ],
                    ),
                  ),

                  // Bottom Sheet Peek
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191022).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.school, color: primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('North Campus Hub', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                      Text('12 students waiting • 0.5 miles away', style: GoogleFonts.publicSans(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: Text('Navigate', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, bool isDark, Color textColor) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191022) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Icon(icon, color: Colors.grey, size: 20),
    );
  }

  Widget _buildBottomNav(bool isDark, Color primaryColor) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1723).withOpacity(0.9) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem('Dashboard', Icons.dashboard, true, primaryColor),
          _buildNavItem('Requests', Icons.hail, false, primaryColor, onTap: () => context.push('/driver_requests')),
          _buildNavItem('Earnings', Icons.account_balance_wallet, false, primaryColor, onTap: () => context.push('/driver_earnings')),
          _buildNavItem('Profile', Icons.person, false, primaryColor, onTap: () => context.push('/driver_profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isSelected, Color primaryColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 20),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isSelected ? primaryColor : Colors.grey,
            ),
          )
        ],
      ),
    );
  }
}
