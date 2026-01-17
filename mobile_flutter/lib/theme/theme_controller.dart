import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_storage.dart';

// Provider for SettingsStorage (assuming it's a singleton or simple class)
final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  return SettingsStorage();
});

// ThemeController
class ThemeController extends Notifier<ThemeMode> {
  
  @override
  ThemeMode build() {
    // Load initial state
    final storage = ref.watch(settingsStorageProvider);
    return storage.loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final storage = ref.read(settingsStorageProvider);
    await storage.saveThemeMode(mode);
  }
}

// Provider for ThemeController
final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(() {
  return ThemeController();
});
