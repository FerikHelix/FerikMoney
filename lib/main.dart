import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/bindings/initial_binding.dart';
import 'app/theme/app_theme.dart';
import 'features/main/main_shell.dart';
import 'services/app_preferences_service.dart';
import 'services/currency_service.dart';
import 'services/privacy_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final themeService = await Get.putAsync(
    () => ThemeService().init(),
    permanent: true,
  );
  await Get.putAsync(() => PrivacyService().init(), permanent: true);
  final preferences = await Get.putAsync(
    () => AppPreferencesService().init(),
    permanent: true,
  );
  Get.put(CurrencyService(preferences), permanent: true);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(FerikMoneyApp(initialThemeMode: themeService.mode.value));
}

class FerikMoneyApp extends StatelessWidget {
  const FerikMoneyApp({super.key, required this.initialThemeMode});

  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FerikMoney',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: initialThemeMode,
      home: const MainShell(),
    );
  }
}
