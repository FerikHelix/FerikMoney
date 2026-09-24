import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../models/backup_data.dart';
import '../utils/money_formatter.dart';

class BackupService {
  BackupService(this.database);

  final AppDatabase database;

  Future<BackupData> createBackup() async {
    final accounts = await database.getAllAccounts();
    final categories = await database.getAllCategories();
    final transactions = await database.getAllTransactions();
    return BackupData(
      exportedAt: DateTime.now(),
      accounts: accounts
          .map(
            (item) => BackupAccount(
              id: item.id,
              name: item.name,
              type: item.type,
              initialBalance: item.initialBalance,
              icon: item.icon,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ),
          )
          .toList(),
      categories: categories
          .map(
            (item) => BackupCategory(
              id: item.id,
              name: item.name,
              type: item.type,
              icon: item.icon,
              createdAt: item.createdAt,
            ),
          )
          .toList(),
      transactions: transactions
          .map(
            (item) => BackupTransaction(
              id: item.id,
              type: item.type,
              amount: item.amount,
              accountId: item.accountId,
              destinationAccountId: item.destinationAccountId,
              categoryId: item.categoryId,
              note: item.note,
              transactionDate: item.transactionDate,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ),
          )
          .toList(),
    );
  }

  String serialize(BackupData backup) =>
      const JsonEncoder.withIndent('  ').convert(backup.toJson());

  Future<Uri?> saveBackup() async {
    final backup = await createBackup();
    final content = serialize(backup);
    return FilePicker.saveFile(
      dialogTitle: 'Simpan backup FerikMoney',
      fileName: _fileName(backup.exportedAt),
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
    );
  }

  Future<void> shareBackup() async {
    final backup = await createBackup();
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, _fileName(backup.exportedAt)));
    await file.writeAsString(serialize(backup), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Backup FerikMoney',
        subject: 'Backup data FerikMoney',
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
  }

  Future<BackupData?> pickAndValidateBackup() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Pilih backup FerikMoney',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return validateJson(utf8.decode(bytes, allowMalformed: false));
  }

  Future<void> restore(BackupData backup) => database.restoreBackup(backup);

  String _fileName(DateTime value) =>
      'ferikmoney_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(value)}.json';

  static BackupData validateJson(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupValidationException('File bukan JSON yang valid.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupValidationException('Struktur backup tidak valid.');
    }
    return validateMap(decoded);
  }

  static BackupData validateMap(Map<String, dynamic> root) {
    if (root['app'] != 'FerikMoney') {
      throw const BackupValidationException(
        'File ini bukan backup FerikMoney.',
      );
    }
    if (root['version'] != BackupData.currentVersion) {
      throw const BackupValidationException(
        'Versi backup tidak didukung oleh aplikasi ini.',
      );
    }
    final exportedAt = _date(root['exportedAt'], 'exportedAt');
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupValidationException('Bagian data backup tidak valid.');
    }
    final accountItems = _list(data['accounts'], 'accounts');
    final categoryItems = _list(data['categories'], 'categories');
    final transactionItems = _list(data['transactions'], 'transactions');

    final accountIds = <String>{};
    final accounts = <BackupAccount>[];
    for (var i = 0; i < accountItems.length; i++) {
      final item = _map(accountItems[i], 'accounts[$i]');
      final id = _string(item['id'], 'accounts[$i].id');
      if (!accountIds.add(id)) {
        throw BackupValidationException('ID akun duplikat: $id.');
      }
      final type = _string(item['type'], 'accounts[$i].type');
      if (!const {'cash', 'bank', 'ewallet', 'other'}.contains(type)) {
        throw BackupValidationException(
          'Jenis akun tidak valid pada akun $id.',
        );
      }
      final balance = _integer(
        item['initialBalance'],
        'accounts[$i].initialBalance',
      );
      if (balance < 0 || balance > maxMoneyAmount) {
        throw BackupValidationException('Saldo awal akun $id tidak valid.');
      }
      accounts.add(
        BackupAccount(
          id: id,
          name: _string(item['name'], 'accounts[$i].name'),
          type: type,
          initialBalance: balance,
          icon: _string(item['icon'], 'accounts[$i].icon'),
          createdAt: _date(item['createdAt'], 'accounts[$i].createdAt'),
          updatedAt: _date(item['updatedAt'], 'accounts[$i].updatedAt'),
        ),
      );
    }

    final categoryIds = <String>{};
    final categoryTypes = <String, String>{};
    final categories = <BackupCategory>[];
    for (var i = 0; i < categoryItems.length; i++) {
      final item = _map(categoryItems[i], 'categories[$i]');
      final id = _string(item['id'], 'categories[$i].id');
      if (!categoryIds.add(id)) {
        throw BackupValidationException('ID kategori duplikat: $id.');
      }
      final type = _string(item['type'], 'categories[$i].type');
      if (!const {'income', 'expense'}.contains(type)) {
        throw BackupValidationException(
          'Jenis kategori tidak valid pada kategori $id.',
        );
      }
      categoryTypes[id] = type;
      categories.add(
        BackupCategory(
          id: id,
          name: _string(item['name'], 'categories[$i].name'),
          type: type,
          icon: _string(item['icon'], 'categories[$i].icon'),
          createdAt: _date(item['createdAt'], 'categories[$i].createdAt'),
        ),
      );
    }

    final transactionIds = <String>{};
    final transactions = <BackupTransaction>[];
    for (var i = 0; i < transactionItems.length; i++) {
      final item = _map(transactionItems[i], 'transactions[$i]');
      final id = _string(item['id'], 'transactions[$i].id');
      if (!transactionIds.add(id)) {
        throw BackupValidationException('ID transaksi duplikat: $id.');
      }
      final type = _string(item['type'], 'transactions[$i].type');
      if (!const {'income', 'expense', 'transfer'}.contains(type)) {
        throw BackupValidationException(
          'Jenis transaksi tidak valid pada transaksi $id.',
        );
      }
      final amount = _integer(item['amount'], 'transactions[$i].amount');
      if (amount <= 0 || amount > maxMoneyAmount) {
        throw BackupValidationException('Nominal transaksi $id tidak valid.');
      }
      final accountId = _string(
        item['accountId'],
        'transactions[$i].accountId',
      );
      if (!accountIds.contains(accountId)) {
        throw BackupValidationException(
          'Transaksi $id merujuk akun yang tidak ditemukan.',
        );
      }
      final destinationId = _nullableString(
        item['destinationAccountId'],
        'transactions[$i].destinationAccountId',
      );
      final categoryId = _nullableString(
        item['categoryId'],
        'transactions[$i].categoryId',
      );
      if (type == 'transfer') {
        if (destinationId == null || !accountIds.contains(destinationId)) {
          throw BackupValidationException(
            'Akun tujuan transaksi $id tidak ditemukan.',
          );
        }
        if (destinationId == accountId) {
          throw BackupValidationException(
            'Akun asal dan tujuan transaksi $id sama.',
          );
        }
        if (categoryId != null) {
          throw BackupValidationException(
            'Transfer $id tidak boleh memiliki kategori.',
          );
        }
      } else {
        if (destinationId != null) {
          throw BackupValidationException(
            'Transaksi $id memiliki akun tujuan yang tidak semestinya.',
          );
        }
        if (categoryId == null || categoryTypes[categoryId] != type) {
          throw BackupValidationException(
            'Kategori transaksi $id tidak ditemukan atau tidak sesuai.',
          );
        }
      }
      transactions.add(
        BackupTransaction(
          id: id,
          type: type,
          amount: amount,
          accountId: accountId,
          destinationAccountId: destinationId,
          categoryId: categoryId,
          note: _nullableString(item['note'], 'transactions[$i].note'),
          transactionDate: _date(
            item['transactionDate'],
            'transactions[$i].transactionDate',
          ),
          createdAt: _date(item['createdAt'], 'transactions[$i].createdAt'),
          updatedAt: _date(item['updatedAt'], 'transactions[$i].updatedAt'),
        ),
      );
    }
    return BackupData(
      exportedAt: exportedAt,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
    );
  }

  static List<dynamic> _list(Object? value, String field) {
    if (value is! List<dynamic>) {
      throw BackupValidationException('$field harus berupa daftar.');
    }
    return value;
  }

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is! Map<String, dynamic>) {
      throw BackupValidationException('$field tidak valid.');
    }
    return value;
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw BackupValidationException('$field harus berupa teks.');
    }
    return value.trim();
  }

  static String? _nullableString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) {
      throw BackupValidationException('$field harus berupa teks atau null.');
    }
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  static int _integer(Object? value, String field) {
    if (value is! int) {
      throw BackupValidationException('$field harus berupa bilangan bulat.');
    }
    return value;
  }

  static DateTime _date(Object? value, String field) {
    if (value is! String) {
      throw BackupValidationException('$field harus berupa tanggal.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupValidationException('$field bukan tanggal yang valid.');
    }
    return parsed;
  }
}
