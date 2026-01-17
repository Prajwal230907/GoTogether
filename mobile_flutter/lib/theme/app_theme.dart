import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  
  static ThemeData light() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      primaryContainer: AppColorsLight.primaryContainer,
      onPrimaryContainer: AppColorsLight.onPrimaryContainer,
      secondary: AppColorsLight.secondary,
      onSecondary: AppColorsLight.onSecondary,
      secondaryContainer: AppColorsLight.secondaryContainer,
      onSecondaryContainer: AppColorsLight.onSecondaryContainer,
      error: AppColorsLight.error,
      onError: AppColorsLight.onError,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.onSurface,
      surfaceContainerHighest: AppColorsLight.surfaceVariant, 
      onSurfaceVariant: AppColorsLight.onSurfaceVariant,
      outline: AppColorsLight.outline,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      onPrimaryContainer: AppColorsDark.onPrimaryContainer,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.onSecondary,
      secondaryContainer: AppColorsDark.secondaryContainer,
      onSecondaryContainer: AppColorsDark.onSecondaryContainer,
      error: AppColorsDark.error,
      onError: AppColorsDark.onError,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.onSurface,
      surfaceContainerHighest: AppColorsDark.surfaceVariant,
      onSurfaceVariant: AppColorsDark.onSurfaceVariant,
      outline: AppColorsDark.outline,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface, // Matches background in ColorScheme usually, but explicit here
      dividerColor: colorScheme.outline,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Usually transparent if using gradients in UI
        foregroundColor: colorScheme.onSurface, // Default, but overridden if gradient
        centerTitle: true,
        elevation: 0,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        titleLarge: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold), 
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
