import 'package:flutter/material.dart';

class AppColorsLight {
  static const Color primary = Color(0xFF2F80FF);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFD0E4FF);
  static const Color onPrimaryContainer = Color(0xFF001D36);

  static const Color secondary = Color(0xFF535F70);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFD7E3F7);
  static const Color onSecondaryContainer = Color(0xFF101C2B);

  static const Color error = Color(0xFFEF4444);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color onSuccess = Colors.white;
  
  static const Color background = Color(0xFFF5F5F7);
  static const Color onBackground = Color(0xFF111827);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  
  static const Color outline = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Gradients
  static const Color primaryGradientStart = Color(0xFF2F80FF);
  static const Color primaryGradientEnd = Color(0xFF00C6FF);
}

class AppColorsDark {
  static const Color primary = Color(0xFF3B82F6);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFF1D4ED8);
  static const Color onPrimaryContainer = Color(0xFFDBEAFE);

  static const Color secondary = Color(0xFF64748B);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFF1E293B);
  static const Color onSecondaryContainer = Color(0xFF94A3B8);

  static const Color error = Color(0xFFF87171);
  static const Color onError = Color(0xFF450A0A);
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color onSuccess = Colors.black;

  static const Color background = Color(0xFF020617); // Deep Navy
  static const Color onBackground = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFF020617);
  static const Color onSurface = Color(0xFFE5E7EB);
  
  // Slightly elevated surface for cards/inputs
  static const Color surfaceVariant = Color(0xFF0F172A); 
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);
  
  static const Color outline = Color(0xFF1F2933);
  static const Color divider = Color(0xFF1F2933);

  // Gradients
  static const Color primaryGradientStart = Color(0xFF0F172A);
  static const Color primaryGradientEnd = Color(0xFF1E3A8A); // Deep Blue
}
