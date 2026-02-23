import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Safety Center', style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SOS Button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Signal Sent to Emergency Contacts!')));
                  },
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 160, height: 160,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos, color: Colors.white, size: 60),
                            Text('SOS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Safety Tools', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSafetyOption(context, Icons.share_location, 'Share Ride Details', 'Share your live location with trusted contacts', Colors.blue),
            const SizedBox(height: 16),
            _buildSafetyOption(context, Icons.contact_phone, 'Emergency Contacts', 'Manage your trusted contacts', Colors.orange),
            const SizedBox(height: 16),
            _buildSafetyOption(context, Icons.local_police, 'Call Police', 'Call 911 immediately', Colors.red),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyOption(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
