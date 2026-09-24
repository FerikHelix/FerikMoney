import 'package:ferikmoney/services/privacy_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('money visibility is persisted in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await PrivacyService().init();
    expect(service.showMoney.value, isTrue);

    await service.toggleMoneyVisibility();
    expect(service.showMoney.value, isFalse);

    final restored = await PrivacyService().init();
    expect(restored.showMoney.value, isFalse);
  });
}
