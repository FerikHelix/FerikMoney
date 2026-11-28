// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'FerikMoney';

  @override
  String get navHome => 'Beranda';

  @override
  String get navWallets => 'Kantong';

  @override
  String get navAnalytics => 'Analitik';

  @override
  String get navSubscriptions => 'Langganan';

  @override
  String get navDebts => 'Utang';

  @override
  String get settings => 'Pengaturan';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Ubah';

  @override
  String get archive => 'Arsipkan';

  @override
  String get close => 'Tutup';

  @override
  String get add => 'Tambah';

  @override
  String get retry => 'Coba lagi';

  @override
  String get seeAll => 'Lihat semua';

  @override
  String get allWallets => 'Semua kantong';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Ikuti sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get about => 'Tentang';

  @override
  String versionLabel(String version) {
    return 'Versi $version';
  }

  @override
  String get notFound => 'Halaman tidak ditemukan';

  @override
  String get totalBalance => 'Total saldo';

  @override
  String get thisMonth => 'Bulan ini';

  @override
  String get income => 'Pemasukan';

  @override
  String get expense => 'Pengeluaran';

  @override
  String get net => 'Selisih';

  @override
  String get recentActivity => 'Transaksi terakhir';

  @override
  String get emptyTransactionsBody => 'Belum ada transaksi.';

  @override
  String get addTransaction => 'Tambah transaksi';

  @override
  String get addExpense => 'Tambah pengeluaran';

  @override
  String get addIncome => 'Tambah pemasukan';

  @override
  String get addTransfer => 'Transfer';

  @override
  String get subscriptionDue => 'Langganan jatuh tempo';

  @override
  String subscriptionDueCount(int count) {
    return '$count langganan jatuh tempo';
  }

  @override
  String get dismiss => 'Tutup';

  @override
  String get firstWalletTitle => 'Buat kantong pertama';

  @override
  String get firstWalletBody => 'Tambahkan kantong untuk mulai mencatat uang.';

  @override
  String get skipForNow => 'Lewati dulu';

  @override
  String get createWallet => 'Buat kantong';

  @override
  String get walletsTitle => 'Kantong';

  @override
  String get activeWallets => 'Aktif';

  @override
  String get archivedWallets => 'Diarsipkan';

  @override
  String get noWalletsBody => 'Belum ada kantong.';

  @override
  String get walletName => 'Nama kantong';

  @override
  String get walletNameRequired => 'Nama kantong wajib diisi';

  @override
  String get walletNameDuplicate => 'Nama kantong sudah dipakai';

  @override
  String get duplicateName => 'Nama sudah dipakai';

  @override
  String get walletType => 'Jenis';

  @override
  String get typeCash => 'Tunai';

  @override
  String get typeBank => 'Bank';

  @override
  String get typeEwallet => 'E-Wallet';

  @override
  String get typeOther => 'Lainnya';

  @override
  String get openingBalance => 'Saldo awal';

  @override
  String get iconLabel => 'Ikon';

  @override
  String get colorLabel => 'Warna';

  @override
  String get editWallet => 'Ubah kantong';

  @override
  String get newWallet => 'Kantong baru';

  @override
  String get walletDetail => 'Detail kantong';

  @override
  String get archiveWallet => 'Arsipkan kantong';

  @override
  String get archiveWalletBody =>
      'Kantong disembunyikan dari pilihan transaksi baru. Riwayatnya tetap tersimpan.';

  @override
  String get deleteWallet => 'Hapus kantong';

  @override
  String get deleteWalletBody => 'Kantong dan saldo awalnya dihapus permanen.';

  @override
  String get lastWalletBlocked => 'Minimal satu kantong harus tetap aktif.';

  @override
  String get walletHasTransactions =>
      'Kantong ini punya transaksi. Arsipkan saja.';

  @override
  String get walletSaved => 'Kantong disimpan';

  @override
  String get walletArchived => 'Kantong diarsipkan';

  @override
  String get walletDeleted => 'Kantong dihapus';

  @override
  String get negativeBalance => 'Saldo minus';

  @override
  String get transactionHistory => 'Riwayat transaksi';

  @override
  String get newExpense => 'Pengeluaran baru';

  @override
  String get newIncome => 'Pemasukan baru';

  @override
  String get newTransfer => 'Transfer baru';

  @override
  String get amount => 'Nominal';

  @override
  String get amountRequired => 'Nominal harus lebih dari Rp 0';

  @override
  String get amountTooLarge => 'Nominal maksimal Rp 999.999.999.999';

  @override
  String get date => 'Tanggal';

  @override
  String get note => 'Catatan';

  @override
  String get optional => 'Opsional';

  @override
  String get wallet => 'Kantong';

  @override
  String get category => 'Kategori';

  @override
  String get sourceWallet => 'Dari kantong';

  @override
  String get destinationWallet => 'Ke kantong';

  @override
  String get transferFee => 'Biaya transfer';

  @override
  String get sameWallet => 'Kantong asal dan tujuan harus berbeda';

  @override
  String get insufficientBalance =>
      'Saldo tidak cukup. Simpan tetap membuat saldo minus.';

  @override
  String get saveExpense => 'Simpan pengeluaran';

  @override
  String get saveIncome => 'Simpan pemasukan';

  @override
  String get saveTransfer => 'Simpan transfer';

  @override
  String get expenseSaved => 'Pengeluaran disimpan';

  @override
  String get incomeSaved => 'Pemasukan disimpan';

  @override
  String get transferSaved => 'Transfer disimpan';

  @override
  String get deleteTransaction => 'Hapus transaksi';

  @override
  String get deleteTransactionBody =>
      'Transaksi dihapus dan saldo dikembalikan.';

  @override
  String get transactionDeleted => 'Transaksi dihapus';

  @override
  String get categoryManagement => 'Kategori';

  @override
  String get newCategory => 'Kategori baru';

  @override
  String get categoryName => 'Nama kategori';

  @override
  String get categoryNameRequired => 'Nama kategori wajib diisi';

  @override
  String get expenseCategory => 'Kategori pengeluaran';

  @override
  String get incomeCategory => 'Kategori pemasukan';

  @override
  String get archiveCategory => 'Arsipkan kategori';

  @override
  String get categoryArchived => 'Kategori diarsipkan';

  @override
  String get categorySaved => 'Kategori disimpan';

  @override
  String get noCategoriesBody => 'Belum ada kategori.';

  @override
  String get dueDayInvalid => 'Tanggal harus 1 sampai 31';

  @override
  String get leadDaysInvalid => 'Isi 0 sampai 30 hari';

  @override
  String get transferCategory => 'Biaya Transfer';

  @override
  String get emptyHistoryBody => 'Transaksi yang dicatat akan muncul di sini.';

  @override
  String get futureDate => 'Tanggal tidak boleh setelah hari ini.';

  @override
  String get discardChanges => 'Buang perubahan';

  @override
  String get discardChangesBody => 'Perubahan yang belum disimpan akan hilang.';

  @override
  String get discard => 'Buang';

  @override
  String get negativeBalanceConfirm => 'Saldo akan menjadi minus. Lanjutkan?';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get analyticsTitle => 'Analitik';

  @override
  String get selectMonth => 'Pilih bulan';

  @override
  String get noDataMonth => 'Tidak ada data pada bulan ini.';

  @override
  String get noDataMonthBody => 'Catat transaksi untuk melihat ringkasan.';

  @override
  String get expenseBreakdown => 'Pengeluaran per kategori';

  @override
  String get incomeBreakdown => 'Pemasukan per kategori';

  @override
  String get trendTitle => 'Tren 6 bulan';

  @override
  String get incomeShort => 'Masuk';

  @override
  String get expenseShort => 'Keluar';

  @override
  String percentage(String value) {
    return '$value%';
  }

  @override
  String get subscriptionsTitle => 'Langganan';

  @override
  String get newSubscription => 'Langganan baru';

  @override
  String get editSubscription => 'Ubah langganan';

  @override
  String get subscriptionName => 'Nama langganan';

  @override
  String get subscriptionNameRequired => 'Nama langganan wajib diisi';

  @override
  String get cycle => 'Siklus';

  @override
  String get monthly => 'Bulanan';

  @override
  String get yearly => 'Tahunan';

  @override
  String get dueDay => 'Tanggal jatuh tempo';

  @override
  String get dueMonth => 'Bulan jatuh tempo';

  @override
  String get leadDays => 'Ingatkan sebelum';

  @override
  String daysBefore(int count) {
    return '$count hari';
  }

  @override
  String get activeLabel => 'Aktif';

  @override
  String get inactiveLabel => 'Nonaktif';

  @override
  String get pay => 'Bayar';

  @override
  String get skipCycle => 'Lewati siklus';

  @override
  String get skipCycleBody =>
      'Jatuh tempo maju satu siklus tanpa mencatat pengeluaran.';

  @override
  String get skip => 'Lewati';

  @override
  String get subscriptionSkipped => 'Siklus dilewati';

  @override
  String get subscriptionSaved => 'Langganan disimpan';

  @override
  String nextDue(String date) {
    return 'Jatuh tempo $date';
  }

  @override
  String get overdue => 'Terlambat';

  @override
  String get noSubscriptionsBody => 'Belum ada langganan.';

  @override
  String get dueSoon => 'Jatuh tempo';

  @override
  String get deactivate => 'Nonaktifkan';

  @override
  String get activate => 'Aktifkan';

  @override
  String get debtsTitle => 'Utang';

  @override
  String get utang => 'Utang';

  @override
  String get piutang => 'Piutang';

  @override
  String get newDebt => 'Catat utang';

  @override
  String get newReceivable => 'Catat piutang';

  @override
  String get counterparty => 'Nama pihak';

  @override
  String get counterpartyRequired => 'Nama pihak wajib diisi';

  @override
  String get principal => 'Pokok';

  @override
  String get startDate => 'Tanggal mulai';

  @override
  String get dueDate => 'Jatuh tempo';

  @override
  String get remaining => 'Sisa';

  @override
  String get settled => 'Lunas';

  @override
  String get openStatus => 'Belum lunas';

  @override
  String get recordPayment => 'Catat pembayaran';

  @override
  String get paymentAmount => 'Nominal pembayaran';

  @override
  String paymentTooLarge(String amount) {
    return 'Pembayaran maksimal $amount';
  }

  @override
  String get paymentSaved => 'Pembayaran disimpan';

  @override
  String get debtSaved => 'Utang disimpan';

  @override
  String get receivableSaved => 'Piutang disimpan';

  @override
  String get totalUtang => 'Total utang';

  @override
  String get totalPiutang => 'Total piutang';

  @override
  String get noDebtsBody => 'Belum ada utang atau piutang.';

  @override
  String get commitToMoney => 'Catat ke saldo';

  @override
  String get commitHint => 'Membuat transaksi di kantong terpilih.';

  @override
  String commitIncomeTo(String wallet) {
    return 'Pemasukan ke $wallet';
  }

  @override
  String commitExpenseFrom(String wallet) {
    return 'Pengeluaran dari $wallet';
  }

  @override
  String get committedLabel => 'Sudah dicatat';

  @override
  String get deleteDebt => 'Hapus catatan';

  @override
  String get deleteDebtBody =>
      'Catatan dan pembayarannya dihapus. Transaksi yang sudah dicatat tetap ada.';

  @override
  String get debtDeleted => 'Catatan dihapus';

  @override
  String get paymentsTitle => 'Pembayaran';

  @override
  String get noPaymentsBody => 'Belum ada pembayaran.';

  @override
  String get dataStoredLocally => 'Data disimpan di perangkat ini.';

  @override
  String get saveFailed => 'Gagal menyimpan. Coba lagi.';

  @override
  String get loadFailed => 'Gagal memuat data.';

  @override
  String get requiredField => 'Wajib diisi';

  @override
  String get invalidNumber => 'Masukkan angka';
}
