import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Stack(
        children: [
          // Background Gradient Logic (optional)
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                   // Nav Bar
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         IconButton(
                           icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                           onPressed: () => context.pop(),
                         ),
                         Text('Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                         IconButton(
                           icon: Icon(Icons.settings, color: textColor),
                           onPressed: () {}, // Settings
                         ),
                       ],
                     ),
                   ),

                   // Profile Header
                   _buildProfileHeader(context, primaryColor, textColor),

                   const SizedBox(height: 24),

                   // Impact Dashboard
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Row(
                       children: [
                         Expanded(child: _buildStatCard(context, Icons.star, '4.9', 'User Rating', Colors.amber)),
                         const SizedBox(width: 16),
                         Expanded(child: _buildStatCard(context, Icons.eco, '12.5 kg', 'CO2 Saved', Colors.green)),
                       ],
                     ),
                   ),

                   const SizedBox(height: 32),

                   // Account Management
                   _buildSectionTitle(context, 'Account Management'),
                   const SizedBox(height: 16),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Column(
                       children: [
                         _buildMenuItem(context, Icons.person_outline, 'Edit Profile', 'Personal details & social links', () {}),
                         const SizedBox(height: 12),
                         _buildMenuItem(context, Icons.account_balance_wallet, 'Wallet', 'Manage payments & earnings', () => context.push('/wallet')),
                         const SizedBox(height: 12),
                         _buildMenuItem(context, Icons.directions_car, 'Vehicle Management', 'Manage your driver profile', () {}),
                         const SizedBox(height: 12),
                         _buildMenuItem(context, Icons.tune, 'Preferences', 'Ride rules & notifications', () {}),
                       ],
                     ),
                   ),

                   const SizedBox(height: 32),
                   _buildSectionTitle(context, 'Support'),
                   const SizedBox(height: 16),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: _buildMenuItem(context, Icons.help_outline, 'Help & FAQ', '24/7 campus support team', () {}),
                   ),

                   const SizedBox(height: 32),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: InkWell(
                         onTap: () async {
                         await FirebaseAuth.instance.signOut();
                         if (context.mounted) context.go('/auth');
                       },
                       borderRadius: BorderRadius.circular(16),
                       child: Container(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         decoration: BoxDecoration(
                           color: Colors.red.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Colors.red.withOpacity(0.2)),
                         ),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.logout, color: Colors.red),
                             SizedBox(width: 8),
                             Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                           ],
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          // Bottom Nav (Visual Only since we are likely pushing this screen)
           Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _CustomBottomNav(
              selectedIndex: 4,
              onTap: (index) {
                if (index == 0) context.go('/'); // Home
                // Other tabs
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Color primaryColor, Color textColor) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'), // Placeholder
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.black87),
                  SizedBox(width: 4),
                  Text('VERIFIED STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(_userData?['name'] ?? user?.displayName ?? 'Student Name', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 16, color: primaryColor),
            SizedBox(width: 8),
            Text('University Name', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2.0)),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171C26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNav({required this.selectedIndex, required this.onTap});

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
          _NavItem(icon: Icons.home, label: 'Home', isSelected: selectedIndex == 0, onTap: () => onTap(0), isDark: isDark),
          _NavItem(icon: Icons.directions_car, label: 'Trips', isSelected: selectedIndex == 1, onTap: () => onTap(1), isDark: isDark),
          
          // Center Placeholder (Add) - Not distinct in Profile view but keeping structure
           Container(width: 56),

          _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat', isSelected: selectedIndex == 3, onTap: () => onTap(3), isDark: isDark),
          _NavItem(icon: Icons.person_outline, label: 'Profile', isSelected: selectedIndex == 4, onTap: () => onTap(4), isDark: isDark),
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
          Icon(icon, color: isSelected ? (isDark ? AppColorsDark.primary : AppColorsLight.primary) : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? (isDark ? AppColorsDark.primary : AppColorsLight.primary) : Colors.grey)),
        ],
      ),
    );
  }
}
