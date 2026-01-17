import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  // Key for storage
  // "system", "light", "dark"

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final box = Hive.box(_boxName);
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await box.put(_themeKey, modeStr);
  }

  ThemeMode loadThemeMode() {
    if (!Hive.isBoxOpen(_boxName)) {
      // Fallback if accessed before init, though robust app flow handles init in main
      return ThemeMode.system;
    }
    final box = Hive.box(_boxName);
    final modeStr = box.get(_themeKey, defaultValue: 'system') as String;
    
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
