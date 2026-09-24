import 'package:ferikmoney/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('theme mode changes and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await ThemeService().init();
    expect(service.mode.value, ThemeMode.system);

    await service.setMode(ThemeMode.dark);
    expect(service.mode.value, ThemeMode.dark);

    final restored = await ThemeService().init();
    expect(restored.mode.value, ThemeMode.dark);
  });
}
