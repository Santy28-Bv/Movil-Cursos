import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value =
        prefs.getBool('academix_light_theme') == true
            ? ThemeMode.light
            : ThemeMode.dark;
  }

  static Future<void> toggle() async {
    mode.value =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('academix_light_theme', mode.value == ThemeMode.light);
  }
}
