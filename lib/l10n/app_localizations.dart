import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'FerikMoney'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navHome;

  /// No description provided for @navWallets.
  ///
  /// In id, this message translates to:
  /// **'Kantong'**
  String get navWallets;

  /// No description provided for @navAnalytics.
  ///
  /// In id, this message translates to:
  /// **'Analitik'**
  String get navAnalytics;

  /// No description provided for @navSubscriptions.
  ///
  /// In id, this message translates to:
  /// **'Langganan'**
  String get navSubscriptions;

  /// No description provided for @navDebts.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get navDebts;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan'**
  String get archive;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retry;

  /// No description provided for @seeAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get seeAll;

  /// No description provided for @allWallets.
  ///
  /// In id, this message translates to:
  /// **'Semua kantong'**
  String get allWallets;

  /// No description provided for @theme.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @about.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String versionLabel(String version);

  /// No description provided for @notFound.
  ///
  /// In id, this message translates to:
  /// **'Halaman tidak ditemukan'**
  String get notFound;

  /// No description provided for @totalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total saldo'**
  String get totalBalance;

  /// No description provided for @thisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get thisMonth;

  /// No description provided for @income.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get expense;

  /// No description provided for @net.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get net;

  /// No description provided for @recentActivity.
  ///
  /// In id, this message translates to:
  /// **'Transaksi terakhir'**
  String get recentActivity;

  /// No description provided for @emptyTransactionsBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi.'**
  String get emptyTransactionsBody;

  /// No description provided for @addTransaction.
  ///
  /// In id, this message translates to:
  /// **'Tambah transaksi'**
  String get addTransaction;

  /// No description provided for @addExpense.
  ///
  /// In id, this message translates to:
  /// **'Tambah pengeluaran'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In id, this message translates to:
  /// **'Tambah pemasukan'**
  String get addIncome;

  /// No description provided for @addTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get addTransfer;

  /// No description provided for @subscriptionDue.
  ///
  /// In id, this message translates to:
  /// **'Langganan jatuh tempo'**
  String get subscriptionDue;

  /// No description provided for @subscriptionDueCount.
  ///
  /// In id, this message translates to:
  /// **'{count} langganan jatuh tempo'**
  String subscriptionDueCount(int count);

  /// No description provided for @dismiss.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get dismiss;

  /// No description provided for @firstWalletTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat kantong pertama'**
  String get firstWalletTitle;

  /// No description provided for @firstWalletBody.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan kantong untuk mulai mencatat uang.'**
  String get firstWalletBody;

  /// No description provided for @skipForNow.
  ///
  /// In id, this message translates to:
  /// **'Lewati dulu'**
  String get skipForNow;

  /// No description provided for @createWallet.
  ///
  /// In id, this message translates to:
  /// **'Buat kantong'**
  String get createWallet;

  /// No description provided for @walletsTitle.
  ///
  /// In id, this message translates to:
  /// **'Kantong'**
  String get walletsTitle;

  /// No description provided for @activeWallets.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get activeWallets;

  /// No description provided for @archivedWallets.
  ///
  /// In id, this message translates to:
  /// **'Diarsipkan'**
  String get archivedWallets;

  /// No description provided for @noWalletsBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kantong.'**
  String get noWalletsBody;

  /// No description provided for @walletName.
  ///
  /// In id, this message translates to:
  /// **'Nama kantong'**
  String get walletName;

  /// No description provided for @walletNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama kantong wajib diisi'**
  String get walletNameRequired;

  /// No description provided for @walletNameDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Nama kantong sudah dipakai'**
  String get walletNameDuplicate;

  /// No description provided for @duplicateName.
  ///
  /// In id, this message translates to:
  /// **'Nama sudah dipakai'**
  String get duplicateName;

  /// No description provided for @walletType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get walletType;

  /// No description provided for @typeCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get typeCash;

  /// No description provided for @typeBank.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get typeBank;

  /// No description provided for @typeEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get typeEwallet;

  /// No description provided for @typeOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get typeOther;

  /// No description provided for @openingBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get openingBalance;

  /// No description provided for @iconLabel.
  ///
  /// In id, this message translates to:
  /// **'Ikon'**
  String get iconLabel;

  /// No description provided for @colorLabel.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get colorLabel;

  /// No description provided for @editWallet.
  ///
  /// In id, this message translates to:
  /// **'Ubah kantong'**
  String get editWallet;

  /// No description provided for @newWallet.
  ///
  /// In id, this message translates to:
  /// **'Kantong baru'**
  String get newWallet;

  /// No description provided for @walletDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail kantong'**
  String get walletDetail;

  /// No description provided for @archiveWallet.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan kantong'**
  String get archiveWallet;

  /// No description provided for @archiveWalletBody.
  ///
  /// In id, this message translates to:
  /// **'Kantong disembunyikan dari pilihan transaksi baru. Riwayatnya tetap tersimpan.'**
  String get archiveWalletBody;

  /// No description provided for @deleteWallet.
  ///
  /// In id, this message translates to:
  /// **'Hapus kantong'**
  String get deleteWallet;

  /// No description provided for @deleteWalletBody.
  ///
  /// In id, this message translates to:
  /// **'Kantong dan saldo awalnya dihapus permanen.'**
  String get deleteWalletBody;

  /// No description provided for @lastWalletBlocked.
  ///
  /// In id, this message translates to:
  /// **'Minimal satu kantong harus tetap aktif.'**
  String get lastWalletBlocked;

  /// No description provided for @walletHasTransactions.
  ///
  /// In id, this message translates to:
  /// **'Kantong ini punya transaksi. Arsipkan saja.'**
  String get walletHasTransactions;

  /// No description provided for @walletSaved.
  ///
  /// In id, this message translates to:
  /// **'Kantong disimpan'**
  String get walletSaved;

  /// No description provided for @walletArchived.
  ///
  /// In id, this message translates to:
  /// **'Kantong diarsipkan'**
  String get walletArchived;

  /// No description provided for @walletDeleted.
  ///
  /// In id, this message translates to:
  /// **'Kantong dihapus'**
  String get walletDeleted;

  /// No description provided for @negativeBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo minus'**
  String get negativeBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat transaksi'**
  String get transactionHistory;

  /// No description provided for @newExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran baru'**
  String get newExpense;

  /// No description provided for @newIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan baru'**
  String get newIncome;

  /// No description provided for @newTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer baru'**
  String get newTransfer;

  /// No description provided for @amount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari Rp 0'**
  String get amountRequired;

  /// No description provided for @amountTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Nominal maksimal Rp 999.999.999.999'**
  String get amountTooLarge;

  /// No description provided for @date.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get date;

  /// No description provided for @note.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get note;

  /// No description provided for @optional.
  ///
  /// In id, this message translates to:
  /// **'Opsional'**
  String get optional;

  /// No description provided for @wallet.
  ///
  /// In id, this message translates to:
  /// **'Kantong'**
  String get wallet;

  /// No description provided for @category.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @sourceWallet.
  ///
  /// In id, this message translates to:
  /// **'Dari kantong'**
  String get sourceWallet;

  /// No description provided for @destinationWallet.
  ///
  /// In id, this message translates to:
  /// **'Ke kantong'**
  String get destinationWallet;

  /// No description provided for @transferFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya transfer'**
  String get transferFee;

  /// No description provided for @sameWallet.
  ///
  /// In id, this message translates to:
  /// **'Kantong asal dan tujuan harus berbeda'**
  String get sameWallet;

  /// No description provided for @insufficientBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo tidak cukup. Simpan tetap membuat saldo minus.'**
  String get insufficientBalance;

  /// No description provided for @saveExpense.
  ///
  /// In id, this message translates to:
  /// **'Simpan pengeluaran'**
  String get saveExpense;

  /// No description provided for @saveIncome.
  ///
  /// In id, this message translates to:
  /// **'Simpan pemasukan'**
  String get saveIncome;

  /// No description provided for @saveTransfer.
  ///
  /// In id, this message translates to:
  /// **'Simpan transfer'**
  String get saveTransfer;

  /// No description provided for @expenseSaved.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran disimpan'**
  String get expenseSaved;

  /// No description provided for @incomeSaved.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan disimpan'**
  String get incomeSaved;

  /// No description provided for @transferSaved.
  ///
  /// In id, this message translates to:
  /// **'Transfer disimpan'**
  String get transferSaved;

  /// No description provided for @deleteTransaction.
  ///
  /// In id, this message translates to:
  /// **'Hapus transaksi'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionBody.
  ///
  /// In id, this message translates to:
  /// **'Transaksi dihapus dan saldo dikembalikan.'**
  String get deleteTransactionBody;

  /// No description provided for @transactionDeleted.
  ///
  /// In id, this message translates to:
  /// **'Transaksi dihapus'**
  String get transactionDeleted;

  /// No description provided for @categoryManagement.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get categoryManagement;

  /// No description provided for @newCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori baru'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori wajib diisi'**
  String get categoryNameRequired;

  /// No description provided for @expenseCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pengeluaran'**
  String get expenseCategory;

  /// No description provided for @incomeCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pemasukan'**
  String get incomeCategory;

  /// No description provided for @archiveCategory.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan kategori'**
  String get archiveCategory;

  /// No description provided for @categoryArchived.
  ///
  /// In id, this message translates to:
  /// **'Kategori diarsipkan'**
  String get categoryArchived;

  /// No description provided for @categorySaved.
  ///
  /// In id, this message translates to:
  /// **'Kategori disimpan'**
  String get categorySaved;

  /// No description provided for @noCategoriesBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kategori.'**
  String get noCategoriesBody;

  /// No description provided for @dueDayInvalid.
  ///
  /// In id, this message translates to:
  /// **'Tanggal harus 1 sampai 31'**
  String get dueDayInvalid;

  /// No description provided for @leadDaysInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isi 0 sampai 30 hari'**
  String get leadDaysInvalid;

  /// No description provided for @transferCategory.
  ///
  /// In id, this message translates to:
  /// **'Biaya Transfer'**
  String get transferCategory;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In id, this message translates to:
  /// **'Transaksi yang dicatat akan muncul di sini.'**
  String get emptyHistoryBody;

  /// No description provided for @futureDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal tidak boleh setelah hari ini.'**
  String get futureDate;

  /// No description provided for @discardChanges.
  ///
  /// In id, this message translates to:
  /// **'Buang perubahan'**
  String get discardChanges;

  /// No description provided for @discardChangesBody.
  ///
  /// In id, this message translates to:
  /// **'Perubahan yang belum disimpan akan hilang.'**
  String get discardChangesBody;

  /// No description provided for @discard.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get discard;

  /// No description provided for @negativeBalanceConfirm.
  ///
  /// In id, this message translates to:
  /// **'Saldo akan menjadi minus. Lanjutkan?'**
  String get negativeBalanceConfirm;

  /// No description provided for @continueLabel.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get continueLabel;

  /// No description provided for @analyticsTitle.
  ///
  /// In id, this message translates to:
  /// **'Analitik'**
  String get analyticsTitle;

  /// No description provided for @selectMonth.
  ///
  /// In id, this message translates to:
  /// **'Pilih bulan'**
  String get selectMonth;

  /// No description provided for @noDataMonth.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data pada bulan ini.'**
  String get noDataMonth;

  /// No description provided for @noDataMonthBody.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi untuk melihat ringkasan.'**
  String get noDataMonthBody;

  /// No description provided for @expenseBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per kategori'**
  String get expenseBreakdown;

  /// No description provided for @incomeBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan per kategori'**
  String get incomeBreakdown;

  /// No description provided for @trendTitle.
  ///
  /// In id, this message translates to:
  /// **'Tren 6 bulan'**
  String get trendTitle;

  /// No description provided for @incomeShort.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get incomeShort;

  /// No description provided for @expenseShort.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get expenseShort;

  /// No description provided for @percentage.
  ///
  /// In id, this message translates to:
  /// **'{value}%'**
  String percentage(String value);

  /// No description provided for @subscriptionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Langganan'**
  String get subscriptionsTitle;

  /// No description provided for @newSubscription.
  ///
  /// In id, this message translates to:
  /// **'Langganan baru'**
  String get newSubscription;

  /// No description provided for @editSubscription.
  ///
  /// In id, this message translates to:
  /// **'Ubah langganan'**
  String get editSubscription;

  /// No description provided for @subscriptionName.
  ///
  /// In id, this message translates to:
  /// **'Nama langganan'**
  String get subscriptionName;

  /// No description provided for @subscriptionNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama langganan wajib diisi'**
  String get subscriptionNameRequired;

  /// No description provided for @cycle.
  ///
  /// In id, this message translates to:
  /// **'Siklus'**
  String get cycle;

  /// No description provided for @monthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In id, this message translates to:
  /// **'Tahunan'**
  String get yearly;

  /// No description provided for @dueDay.
  ///
  /// In id, this message translates to:
  /// **'Tanggal jatuh tempo'**
  String get dueDay;

  /// No description provided for @dueMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan jatuh tempo'**
  String get dueMonth;

  /// No description provided for @leadDays.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan sebelum'**
  String get leadDays;

  /// No description provided for @daysBefore.
  ///
  /// In id, this message translates to:
  /// **'{count} hari'**
  String daysBefore(int count);

  /// No description provided for @activeLabel.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get activeLabel;

  /// No description provided for @inactiveLabel.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get inactiveLabel;

  /// No description provided for @pay.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get pay;

  /// No description provided for @skipCycle.
  ///
  /// In id, this message translates to:
  /// **'Lewati siklus'**
  String get skipCycle;

  /// No description provided for @skipCycleBody.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo maju satu siklus tanpa mencatat pengeluaran.'**
  String get skipCycleBody;

  /// No description provided for @skip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get skip;

  /// No description provided for @subscriptionSkipped.
  ///
  /// In id, this message translates to:
  /// **'Siklus dilewati'**
  String get subscriptionSkipped;

  /// No description provided for @subscriptionSaved.
  ///
  /// In id, this message translates to:
  /// **'Langganan disimpan'**
  String get subscriptionSaved;

  /// No description provided for @nextDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo {date}'**
  String nextDue(String date);

  /// No description provided for @overdue.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get overdue;

  /// No description provided for @noSubscriptionsBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada langganan.'**
  String get noSubscriptionsBody;

  /// No description provided for @dueSoon.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo'**
  String get dueSoon;

  /// No description provided for @deactivate.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan'**
  String get activate;

  /// No description provided for @debtsTitle.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get debtsTitle;

  /// No description provided for @utang.
  ///
  /// In id, this message translates to:
  /// **'Utang'**
  String get utang;

  /// No description provided for @piutang.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get piutang;

  /// No description provided for @newDebt.
  ///
  /// In id, this message translates to:
  /// **'Catat utang'**
  String get newDebt;

  /// No description provided for @newReceivable.
  ///
  /// In id, this message translates to:
  /// **'Catat piutang'**
  String get newReceivable;

  /// No description provided for @counterparty.
  ///
  /// In id, this message translates to:
  /// **'Nama pihak'**
  String get counterparty;

  /// No description provided for @counterpartyRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama pihak wajib diisi'**
  String get counterpartyRequired;

  /// No description provided for @principal.
  ///
  /// In id, this message translates to:
  /// **'Pokok'**
  String get principal;

  /// No description provided for @startDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mulai'**
  String get startDate;

  /// No description provided for @dueDate.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo'**
  String get dueDate;

  /// No description provided for @remaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get remaining;

  /// No description provided for @settled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get settled;

  /// No description provided for @openStatus.
  ///
  /// In id, this message translates to:
  /// **'Belum lunas'**
  String get openStatus;

  /// No description provided for @recordPayment.
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran'**
  String get recordPayment;

  /// No description provided for @paymentAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal pembayaran'**
  String get paymentAmount;

  /// No description provided for @paymentTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran maksimal {amount}'**
  String paymentTooLarge(String amount);

  /// No description provided for @paymentSaved.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran disimpan'**
  String get paymentSaved;

  /// No description provided for @debtSaved.
  ///
  /// In id, this message translates to:
  /// **'Utang disimpan'**
  String get debtSaved;

  /// No description provided for @receivableSaved.
  ///
  /// In id, this message translates to:
  /// **'Piutang disimpan'**
  String get receivableSaved;

  /// No description provided for @totalUtang.
  ///
  /// In id, this message translates to:
  /// **'Total utang'**
  String get totalUtang;

  /// No description provided for @totalPiutang.
  ///
  /// In id, this message translates to:
  /// **'Total piutang'**
  String get totalPiutang;

  /// No description provided for @noDebtsBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada utang atau piutang.'**
  String get noDebtsBody;

  /// No description provided for @commitToMoney.
  ///
  /// In id, this message translates to:
  /// **'Catat ke saldo'**
  String get commitToMoney;

  /// No description provided for @commitHint.
  ///
  /// In id, this message translates to:
  /// **'Membuat transaksi di kantong terpilih.'**
  String get commitHint;

  /// No description provided for @commitIncomeTo.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan ke {wallet}'**
  String commitIncomeTo(String wallet);

  /// No description provided for @commitExpenseFrom.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran dari {wallet}'**
  String commitExpenseFrom(String wallet);

  /// No description provided for @committedLabel.
  ///
  /// In id, this message translates to:
  /// **'Sudah dicatat'**
  String get committedLabel;

  /// No description provided for @deleteDebt.
  ///
  /// In id, this message translates to:
  /// **'Hapus catatan'**
  String get deleteDebt;

  /// No description provided for @deleteDebtBody.
  ///
  /// In id, this message translates to:
  /// **'Catatan dan pembayarannya dihapus. Transaksi yang sudah dicatat tetap ada.'**
  String get deleteDebtBody;

  /// No description provided for @debtDeleted.
  ///
  /// In id, this message translates to:
  /// **'Catatan dihapus'**
  String get debtDeleted;

  /// No description provided for @paymentsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get paymentsTitle;

  /// No description provided for @noPaymentsBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran.'**
  String get noPaymentsBody;

  /// No description provided for @dataStoredLocally.
  ///
  /// In id, this message translates to:
  /// **'Data disimpan di perangkat ini.'**
  String get dataStoredLocally;

  /// No description provided for @saveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan. Coba lagi.'**
  String get saveFailed;

  /// No description provided for @loadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data.'**
  String get loadFailed;

  /// No description provided for @requiredField.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In id, this message translates to:
  /// **'Masukkan angka'**
  String get invalidNumber;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
