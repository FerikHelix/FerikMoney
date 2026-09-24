import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService extends GetxService {
  static const preferenceKey = 'show_money_values';

  late SharedPreferences _preferences;
  final showMoney = true.obs;

  Future<PrivacyService> init() async {
    _preferences = await SharedPreferences.getInstance();
    showMoney.value = _preferences.getBool(preferenceKey) ?? true;
    return this;
  }

  Future<void> toggleMoneyVisibility() async {
    showMoney.toggle();
    await _preferences.setBool(preferenceKey, showMoney.value);
  }
}
