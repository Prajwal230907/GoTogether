
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Added this import
import 'package:mobile_flutter/theme/app_colors.dart';
import 'dart:ui' as dart_ui;

class SplashScreen extends ConsumerStatefulWidget { // Kept ConsumerStatefulWidget
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate loading
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final role = doc.data()!['role'];
            if (role == 'driver') {
              context.go('/driver_home');
            } else {
              context.go('/home');
            }
          } else {
            context.go('/register');
          }
        } catch (e) {
          context.go('/login');
        }
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark mode colors for splash as per design
    const bgColor = AppColorsDark.background;
    const primaryColor = AppColorsDark.primary;
    const purpleColor = AppColorsDark.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0), // Ensure no blur issues if unused
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                    boxShadow: [
                       BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 120,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purpleColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: purpleColor.withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Mark
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, purpleColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Brand Name
                Text(
                  'GoTogether',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    shadows: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 30,
                        offset: Offset.zero,
                      ),
                    ],
                  ) ?? const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Ride Smart. Ride Together.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Area
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Loading Indicator
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INITIALIZING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Text(
                              '75%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 240 * 0.75, // 75%
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryColor, purpleColor],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'COLLEGE EXCLUSIVE NETWORK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
