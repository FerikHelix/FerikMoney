import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService extends GetxService {
  static const _currencyKey = 'currency_code';
  static const _firstWeekdayKey = 'first_weekday';
  static const _defaultAccountKey = 'default_account_id';
  static const _lastExpenseCategoryKey = 'last_expense_category_id';
  static const _lastIncomeCategoryKey = 'last_income_category_id';
  static const _lastAccountKey = 'last_transaction_account_id';
  static const _lastRestoreSignatureKey = 'last_restore_signature';

  late SharedPreferences _preferences;

  final currencyCode = 'IDR'.obs;
  final firstWeekday = DateTime.monday.obs;
  final defaultAccountId = RxnString();
  final lastExpenseCategoryId = RxnString();
  final lastIncomeCategoryId = RxnString();
  final lastAccountId = RxnString();

  Future<AppPreferencesService> init() async {
    _preferences = await SharedPreferences.getInstance();
    currencyCode.value = _preferences.getString(_currencyKey) ?? 'IDR';
    firstWeekday.value =
        _preferences.getInt(_firstWeekdayKey) ?? DateTime.monday;
    defaultAccountId.value = _preferences.getString(_defaultAccountKey);
    lastExpenseCategoryId.value = _preferences.getString(
      _lastExpenseCategoryKey,
    );
    lastIncomeCategoryId.value = _preferences.getString(_lastIncomeCategoryKey);
    lastAccountId.value = _preferences.getString(_lastAccountKey);
    return this;
  }

  Future<void> setCurrency(String value) async {
    currencyCode.value = value;
    await _preferences.setString(_currencyKey, value);
  }

  Future<void> setFirstWeekday(int value) async {
    firstWeekday.value = value;
    await _preferences.setInt(_firstWeekdayKey, value);
  }

  Future<void> setDefaultAccount(String? value) async {
    defaultAccountId.value = value;
    if (value == null) {
      await _preferences.remove(_defaultAccountKey);
    } else {
      await _preferences.setString(_defaultAccountKey, value);
    }
  }

  Future<void> rememberTransaction({
    required String type,
    required String accountId,
    String? categoryId,
  }) async {
    lastAccountId.value = accountId;
    await _preferences.setString(_lastAccountKey, accountId);
    if (categoryId == null) return;
    if (type == 'expense') {
      lastExpenseCategoryId.value = categoryId;
      await _preferences.setString(_lastExpenseCategoryKey, categoryId);
    } else if (type == 'income') {
      lastIncomeCategoryId.value = categoryId;
      await _preferences.setString(_lastIncomeCategoryKey, categoryId);
    }
  }

  String? get lastRestoreSignature =>
      _preferences.getString(_lastRestoreSignatureKey);

  Future<void> setLastRestoreSignature(String value) =>
      _preferences.setString(_lastRestoreSignatureKey, value);

  Map<String, Object?> exportData() => {
    'currencyCode': currencyCode.value,
    'firstWeekday': firstWeekday.value,
    'defaultAccountId': defaultAccountId.value,
  };

  Future<void> importData(Map<String, Object?> data) async {
    final currency = data['currencyCode'];
    if (currency is String) await setCurrency(currency);
    final weekday = data['firstWeekday'];
    if (weekday is int &&
        (weekday == DateTime.monday || weekday == DateTime.sunday)) {
      await setFirstWeekday(weekday);
    }
    final accountId = data['defaultAccountId'];
    await setDefaultAccount(accountId is String ? accountId : null);
  }

  Future<void> clearFinancialPreferences() async {
    await setDefaultAccount(null);
    lastExpenseCategoryId.value = null;
    lastIncomeCategoryId.value = null;
    lastAccountId.value = null;
    await _preferences.remove(_lastExpenseCategoryKey);
    await _preferences.remove(_lastIncomeCategoryKey);
    await _preferences.remove(_lastAccountKey);
    await _preferences.remove(_lastRestoreSignatureKey);
  }
}
