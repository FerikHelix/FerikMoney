import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const _key = 'theme_mode';
  late SharedPreferences _preferences;

  final mode = ThemeMode.system.obs;

  Future<ThemeService> init() async {
    _preferences = await SharedPreferences.getInstance();
    mode.value = switch (_preferences.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return this;
  }

  Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    Get.changeThemeMode(value);
    await _preferences.setString(_key, value.name);
  }
}
