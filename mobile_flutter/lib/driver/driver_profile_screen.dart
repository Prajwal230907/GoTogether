import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF120808) : const Color(0xFFF8F5F5);
    final cardColor = isDark ? const Color(0xFF1E0D0D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF321616) : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = const Color(0xFFF20D0D); // Red

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Driver Profile', style: GoogleFonts.publicSans(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: primaryColor),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Overview
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCA-SseST8_ieWwIVr_D1XhgR69cXPTykIjoNEsG18HWf7BLhDU8ZtOTSjx0S2iv_xop64TkZqjsmeq2dcelLmvzDO_6IX-Foe0YLuCcjf4ArwjxyffuB-fKzPgM4imK42x7-fjzsOb7-PZ91kLCfEBCbxuwxtkxT1tJo01SildS8h-oj7HLJSQ8j5uKP-tfllPgE5eP6c4tawUWtAUkCxjkCLCQOLQN3XDcnmxdtWF6wCa-HUy2KYd2zeGvUwo_h2FNTl3SM9xM8w',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgColor, width: 4),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_userData?['name'] ?? 'Driver Name', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  Text('Active Driver', style: GoogleFonts.publicSans(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text('STUDENT DRIVER BADGE', style: GoogleFonts.publicSans(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Verification Pill
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('License Verified', style: GoogleFonts.publicSans(color: Colors.teal, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Valid until Dec 2025', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.check_circle, color: Colors.teal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Vehicle Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ACTIVE VEHICLE', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text('Change', style: GoogleFonts.publicSans(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VEHICLE MODEL', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(_userData?['vehicleModel']?.toString().isNotEmpty == true ? _userData!['vehicleModel'] : 'Add Vehicle Model', style: GoogleFonts.publicSans(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.electric_car, color: primaryColor, size: 32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text('CALIFORNIA', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  Text('G0-2GTHR', style: GoogleFonts.publicSans(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Last Inspection', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 12)),
                                Text('Aug 14, 2023', style: GoogleFonts.publicSans(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Documents
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('VEHICLE DOCUMENTS', style: GoogleFonts.publicSans(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildDocItem('Proof of Insurance', 'Expires in 45 days', Icons.description, Colors.blue, cardColor, borderColor, textColor),
                  const SizedBox(height: 12),
                  _buildDocItem('Vehicle Registration', 'Valid until Oct 2024', Icons.article, Colors.purple, cardColor, borderColor, textColor),
                  const SizedBox(height: 12),
                  _buildDocItem('Background Check', 'Cleared & Active', Icons.assignment_turned_in, Colors.orange, cardColor, borderColor, textColor, subtitleColor: Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.push('/driver_verification');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_a_photo, color: primaryColor),
                            const SizedBox(height: 8),
                            Text('Upload Docs', style: GoogleFonts.publicSans(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history, color: primaryColor),
                          const SizedBox(height: 8),
                          Text('Service History', style: GoogleFonts.publicSans(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text('Sign Out', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, IconData icon, MaterialColor color, Color cardColor, Color borderColor, Color textColor, {Color? subtitleColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.publicSans(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.publicSans(color: subtitleColor ?? Colors.grey, fontSize: 12, fontWeight: subtitleColor != null ? FontWeight.w500 : FontWeight.normal)),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
