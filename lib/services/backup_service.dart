import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../models/backup_data.dart';
import '../utils/money_formatter.dart';
import 'app_preferences_service.dart';
import 'privacy_service.dart';
import 'theme_service.dart';

class BackupService {
  BackupService(
    this.database, {
    this.preferences,
    this.themeService,
    this.privacyService,
  });

  final AppDatabase database;
  final AppPreferencesService? preferences;
  final ThemeService? themeService;
  final PrivacyService? privacyService;

  Future<BackupData> createBackup() async {
    final accounts = await database.getAllAccounts();
    final categories = await database.getAllCategories();
    final transactions = await database.getAllTransactions();
    final tags = await database.getAllTags();
    final transactionTags = await database.getAllTransactionTags();
    final budgets = await database.getAllBudgets();
    final recurringRules = await database.getAllRecurringRules();
    final recurringRuleTags = await database.getAllRecurringRuleTags();
    final recurringOccurrences = await database.getAllRecurringOccurrences();
    final savingsGoals = await database.getAllSavingsGoals();
    final savingsGoalTransfers = await database.getAllSavingsGoalTransfers();
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
              isArchived: item.isArchived,
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
              isArchived: item.isArchived,
            ),
          )
          .toList(),
      tags: tags
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'name': item.name,
              'normalizedName': item.normalizedName,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(),
      transactionTags: transactionTags
          .map(
            (item) => <String, Object?>{
              'transactionId': item.transactionId,
              'tagId': item.tagId,
            },
          )
          .toList(),
      budgets: budgets
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'categoryId': item.categoryId,
              'amount': item.amount,
              'isActive': item.isActive,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      recurringRules: recurringRules
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'name': item.name,
              'type': item.type,
              'amount': item.amount,
              'accountId': item.accountId,
              'destinationAccountId': item.destinationAccountId,
              'categoryId': item.categoryId,
              'note': item.note,
              'frequency': item.frequency,
              'startDate': item.startDate.toIso8601String(),
              'nextDueAt': item.nextDueAt.toIso8601String(),
              'isPaused': item.isPaused,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      recurringRuleTags: recurringRuleTags
          .map(
            (item) => <String, Object?>{
              'ruleId': item.ruleId,
              'tagId': item.tagId,
            },
          )
          .toList(),
      recurringOccurrences: recurringOccurrences
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'ruleId': item.ruleId,
              'dueAt': item.dueAt.toIso8601String(),
              'status': item.status,
              'transactionId': item.transactionId,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      savingsGoals: savingsGoals
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'name': item.name,
              'targetAmount': item.targetAmount,
              'targetDate': item.targetDate?.toIso8601String(),
              'isArchived': item.isArchived,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      savingsGoalTransfers: savingsGoalTransfers
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'goalId': item.goalId,
              'accountId': item.accountId,
              'type': item.type,
              'amount': item.amount,
              'note': item.note,
              'transferDate': item.transferDate.toIso8601String(),
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(),
      preferences: {
        ...?preferences?.exportData(),
        if (themeService case final service?)
          'themeMode': service.mode.value.name,
        if (privacyService case final service?)
          'showMoneyValues': service.showMoney.value,
      },
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

  Future<void> restore(BackupData backup) async {
    await database.restoreBackup(backup);
    await preferences?.importData(backup.preferences);
    final themeName = backup.preferences['themeMode'];
    if (themeName is String && themeService != null) {
      final mode = switch (themeName) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      await themeService!.setMode(mode);
    }
    final showMoney = backup.preferences['showMoneyValues'];
    if (showMoney is bool &&
        privacyService != null &&
        privacyService!.showMoney.value != showMoney) {
      await privacyService!.toggleMoneyVisibility();
    }
    await preferences?.setLastRestoreSignature(signatureFor(backup));
  }

  String signatureFor(BackupData backup) {
    String ids(Iterable<String> values) => (values.toList()..sort()).join(',');
    String mapIds(List<Map<String, Object?>> values, String key) =>
        ids(values.map((item) => item[key]).whereType<String>());

    return [
      backup.version,
      ids(backup.accounts.map((item) => item.id)),
      ids(backup.categories.map((item) => item.id)),
      ids(backup.transactions.map((item) => item.id)),
      mapIds(backup.tags, 'id'),
      mapIds(backup.budgets, 'id'),
      mapIds(backup.recurringRules, 'id'),
      mapIds(backup.recurringOccurrences, 'id'),
      mapIds(backup.savingsGoals, 'id'),
      mapIds(backup.savingsGoalTransfers, 'id'),
    ].join('|');
  }

  bool isDuplicateRestore(BackupData backup) =>
      preferences?.lastRestoreSignature == signatureFor(backup);

  Future<String> createCsv() async {
    final transactions = await database.getAllTransactions();
    final accounts = {
      for (final item in await database.getAllAccounts()) item.id: item.name,
    };
    final categories = {
      for (final item in await database.getAllCategories()) item.id: item.name,
    };
    final tags = {
      for (final item in await database.getAllTags()) item.id: item.name,
    };
    final links = await database.getAllTransactionTags();
    final tagsByTransaction = <String, List<String>>{};
    for (final link in links) {
      final name = tags[link.tagId];
      if (name != null) {
        tagsByTransaction.putIfAbsent(link.transactionId, () => []).add(name);
      }
    }
    final currency = preferences?.currencyCode.value ?? 'IDR';
    final rows = <List<Object?>>[
      const [
        'date_time',
        'type',
        'amount_minor',
        'currency',
        'wallet',
        'destination',
        'category',
        'tags',
        'note',
      ],
      ...transactions.map(
        (item) => [
          item.transactionDate.toIso8601String(),
          item.type,
          item.amount,
          currency,
          accounts[item.accountId] ?? '',
          accounts[item.destinationAccountId] ?? '',
          categories[item.categoryId] ?? '',
          (tagsByTransaction[item.id] ?? const <String>[]).join(';'),
          item.note ?? '',
        ],
      ),
    ];
    return '\ufeff${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}';
  }

  Future<Uri?> saveCsv() async {
    final now = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return FilePicker.saveFile(
      dialogTitle: 'Simpan transaksi FerikMoney',
      fileName: 'ferikmoney_transactions_$now.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: Uint8List.fromList(utf8.encode(await createCsv())),
      mimeType: 'text/csv',
    );
  }

  Future<void> shareCsv() async {
    final directory = await getTemporaryDirectory();
    final now = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final file = File(
      p.join(directory.path, 'ferikmoney_transactions_$now.csv'),
    );
    await file.writeAsString(await createCsv(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Transaksi FerikMoney',
        subject: 'Export transaksi FerikMoney',
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
  }

  Future<void> resetData() async {
    await database.resetAllData();
    await preferences?.clearFinancialPreferences();
  }

  static String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

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
    final version = root['version'];
    if (version is! int || (version != 1 && version != 2)) {
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
      if (!const {
        'cash',
        'bank',
        'ewallet',
        'savings',
        'other',
      }.contains(type)) {
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
          isArchived: _optionalBool(
            item['isArchived'],
            'accounts[$i].isArchived',
          ),
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
          isArchived: _optionalBool(
            item['isArchived'],
            'categories[$i].isArchived',
          ),
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
    final tags = _records(data, 'tags', required: version == 2);
    final tagIds = <String>{};
    final normalizedTags = <String>{};
    for (var i = 0; i < tags.length; i++) {
      final id = _string(tags[i]['id'], 'tags[$i].id');
      final normalized = _string(
        tags[i]['normalizedName'],
        'tags[$i].normalizedName',
      );
      if (!tagIds.add(id) || !normalizedTags.add(normalized)) {
        throw BackupValidationException('Tag duplikat: $id.');
      }
      _string(tags[i]['name'], 'tags[$i].name');
      _date(tags[i]['createdAt'], 'tags[$i].createdAt');
    }

    final transactionTags = _records(
      data,
      'transactionTags',
      required: version == 2,
    );
    final transactionTagKeys = <String>{};
    for (var i = 0; i < transactionTags.length; i++) {
      final transactionId = _string(
        transactionTags[i]['transactionId'],
        'transactionTags[$i].transactionId',
      );
      final tagId = _string(
        transactionTags[i]['tagId'],
        'transactionTags[$i].tagId',
      );
      if (!transactionIds.contains(transactionId) || !tagIds.contains(tagId)) {
        throw BackupValidationException(
          'Relasi tag transaksi ke-$i tidak valid.',
        );
      }
      if (!transactionTagKeys.add('$transactionId|$tagId')) {
        throw BackupValidationException('Relasi tag transaksi duplikat.');
      }
    }

    final budgets = _records(data, 'budgets', required: version == 2);
    final budgetIds = <String>{};
    final activeBudgetKeys = <String>{};
    for (var i = 0; i < budgets.length; i++) {
      final id = _string(budgets[i]['id'], 'budgets[$i].id');
      if (!budgetIds.add(id)) {
        throw BackupValidationException('ID budget duplikat: $id.');
      }
      final categoryId = _nullableString(
        budgets[i]['categoryId'],
        'budgets[$i].categoryId',
      );
      if (categoryId != null && categoryTypes[categoryId] != 'expense') {
        throw BackupValidationException('Kategori budget $id tidak valid.');
      }
      final amount = _integer(budgets[i]['amount'], 'budgets[$i].amount');
      if (amount <= 0 || amount > maxMoneyAmount) {
        throw BackupValidationException('Nominal budget $id tidak valid.');
      }
      final active = _bool(budgets[i]['isActive'], 'budgets[$i].isActive');
      if (active && !activeBudgetKeys.add(categoryId ?? '__overall__')) {
        throw BackupValidationException('Ada lebih dari satu budget aktif.');
      }
      _date(budgets[i]['createdAt'], 'budgets[$i].createdAt');
      _date(budgets[i]['updatedAt'], 'budgets[$i].updatedAt');
    }

    final recurringRules = _records(
      data,
      'recurringRules',
      required: version == 2,
    );
    final ruleIds = <String>{};
    for (var i = 0; i < recurringRules.length; i++) {
      final item = recurringRules[i];
      final id = _string(item['id'], 'recurringRules[$i].id');
      if (!ruleIds.add(id)) {
        throw BackupValidationException('ID rule berulang duplikat: $id.');
      }
      _string(item['name'], 'recurringRules[$i].name');
      final type = _string(item['type'], 'recurringRules[$i].type');
      if (!const {'income', 'expense', 'transfer'}.contains(type)) {
        throw BackupValidationException('Jenis rule $id tidak valid.');
      }
      final amount = _integer(item['amount'], 'recurringRules[$i].amount');
      if (amount <= 0 || amount > maxMoneyAmount) {
        throw BackupValidationException('Nominal rule $id tidak valid.');
      }
      final accountId = _string(
        item['accountId'],
        'recurringRules[$i].accountId',
      );
      if (!accountIds.contains(accountId)) {
        throw BackupValidationException('Akun rule $id tidak ditemukan.');
      }
      final destinationId = _nullableString(
        item['destinationAccountId'],
        'recurringRules[$i].destinationAccountId',
      );
      final categoryId = _nullableString(
        item['categoryId'],
        'recurringRules[$i].categoryId',
      );
      if (type == 'transfer') {
        if (destinationId == null ||
            destinationId == accountId ||
            !accountIds.contains(destinationId) ||
            categoryId != null) {
          throw BackupValidationException(
            'Tujuan rule transfer $id tidak valid.',
          );
        }
      } else if (destinationId != null || categoryTypes[categoryId] != type) {
        throw BackupValidationException('Kategori rule $id tidak valid.');
      }
      final frequency = _string(
        item['frequency'],
        'recurringRules[$i].frequency',
      );
      if (!const {'daily', 'weekly', 'monthly', 'yearly'}.contains(frequency)) {
        throw BackupValidationException('Frekuensi rule $id tidak valid.');
      }
      _nullableString(item['note'], 'recurringRules[$i].note');
      _date(item['startDate'], 'recurringRules[$i].startDate');
      _date(item['nextDueAt'], 'recurringRules[$i].nextDueAt');
      _bool(item['isPaused'], 'recurringRules[$i].isPaused');
      _date(item['createdAt'], 'recurringRules[$i].createdAt');
      _date(item['updatedAt'], 'recurringRules[$i].updatedAt');
    }

    final recurringRuleTags = _records(
      data,
      'recurringRuleTags',
      required: version == 2,
    );
    final ruleTagKeys = <String>{};
    for (var i = 0; i < recurringRuleTags.length; i++) {
      final ruleId = _string(
        recurringRuleTags[i]['ruleId'],
        'recurringRuleTags[$i].ruleId',
      );
      final tagId = _string(
        recurringRuleTags[i]['tagId'],
        'recurringRuleTags[$i].tagId',
      );
      if (!ruleIds.contains(ruleId) ||
          !tagIds.contains(tagId) ||
          !ruleTagKeys.add('$ruleId|$tagId')) {
        throw BackupValidationException('Relasi tag rule ke-$i tidak valid.');
      }
    }

    final recurringOccurrences = _records(
      data,
      'recurringOccurrences',
      required: version == 2,
    );
    final occurrenceIds = <String>{};
    final dueKeys = <String>{};
    for (var i = 0; i < recurringOccurrences.length; i++) {
      final item = recurringOccurrences[i];
      final id = _string(item['id'], 'recurringOccurrences[$i].id');
      final ruleId = _string(item['ruleId'], 'recurringOccurrences[$i].ruleId');
      final due = _date(item['dueAt'], 'recurringOccurrences[$i].dueAt');
      final status = _string(item['status'], 'recurringOccurrences[$i].status');
      final transactionId = _nullableString(
        item['transactionId'],
        'recurringOccurrences[$i].transactionId',
      );
      if (!occurrenceIds.add(id) ||
          !ruleIds.contains(ruleId) ||
          !dueKeys.add('$ruleId|${due.toIso8601String()}') ||
          !const {'pending', 'created', 'skipped'}.contains(status) ||
          (transactionId != null && !transactionIds.contains(transactionId))) {
        throw BackupValidationException('Occurrence $id tidak valid.');
      }
      _date(item['createdAt'], 'recurringOccurrences[$i].createdAt');
      _date(item['updatedAt'], 'recurringOccurrences[$i].updatedAt');
    }

    final savingsGoals = _records(data, 'savingsGoals', required: version == 2);
    final goalIds = <String>{};
    for (var i = 0; i < savingsGoals.length; i++) {
      final item = savingsGoals[i];
      final id = _string(item['id'], 'savingsGoals[$i].id');
      if (!goalIds.add(id)) {
        throw BackupValidationException('ID goal duplikat: $id.');
      }
      _string(item['name'], 'savingsGoals[$i].name');
      final target = _integer(
        item['targetAmount'],
        'savingsGoals[$i].targetAmount',
      );
      if (target <= 0 || target > maxMoneyAmount) {
        throw BackupValidationException('Target goal $id tidak valid.');
      }
      _nullableDate(item['targetDate'], 'savingsGoals[$i].targetDate');
      _bool(item['isArchived'], 'savingsGoals[$i].isArchived');
      _date(item['createdAt'], 'savingsGoals[$i].createdAt');
      _date(item['updatedAt'], 'savingsGoals[$i].updatedAt');
    }

    final savingsGoalTransfers = _records(
      data,
      'savingsGoalTransfers',
      required: version == 2,
    );
    final goalTransferIds = <String>{};
    for (var i = 0; i < savingsGoalTransfers.length; i++) {
      final item = savingsGoalTransfers[i];
      final id = _string(item['id'], 'savingsGoalTransfers[$i].id');
      final goalId = _string(item['goalId'], 'savingsGoalTransfers[$i].goalId');
      final accountId = _string(
        item['accountId'],
        'savingsGoalTransfers[$i].accountId',
      );
      final type = _string(item['type'], 'savingsGoalTransfers[$i].type');
      final amount = _integer(
        item['amount'],
        'savingsGoalTransfers[$i].amount',
      );
      if (!goalTransferIds.add(id) ||
          !goalIds.contains(goalId) ||
          !accountIds.contains(accountId) ||
          !const {'deposit', 'withdrawal'}.contains(type) ||
          amount <= 0 ||
          amount > maxMoneyAmount) {
        throw BackupValidationException('Transfer goal $id tidak valid.');
      }
      _nullableString(item['note'], 'savingsGoalTransfers[$i].note');
      _date(item['transferDate'], 'savingsGoalTransfers[$i].transferDate');
      _date(item['createdAt'], 'savingsGoalTransfers[$i].createdAt');
    }

    final preferences = _preferences(data, version);
    final defaultAccountId = preferences['defaultAccountId'];
    if (defaultAccountId is String && !accountIds.contains(defaultAccountId)) {
      throw const BackupValidationException(
        'Akun default merujuk akun yang tidak ditemukan.',
      );
    }

    return BackupData(
      version: version,
      exportedAt: exportedAt,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      tags: tags,
      transactionTags: transactionTags,
      budgets: budgets,
      recurringRules: recurringRules,
      recurringRuleTags: recurringRuleTags,
      recurringOccurrences: recurringOccurrences,
      savingsGoals: savingsGoals,
      savingsGoalTransfers: savingsGoalTransfers,
      preferences: preferences,
    );
  }

  static List<Map<String, Object?>> _records(
    Map<String, dynamic> data,
    String field, {
    required bool required,
  }) {
    final raw = data[field];
    if (raw == null && !required) return const [];
    final values = _list(raw, field);
    return [
      for (var i = 0; i < values.length; i++)
        Map<String, Object?>.from(_map(values[i], '$field[$i]')),
    ];
  }

  static Map<String, Object?> _preferences(
    Map<String, dynamic> data,
    int version,
  ) {
    final raw = data['preferences'];
    if (raw == null && version == 1) return const {};
    final result = Map<String, Object?>.from(_map(raw, 'preferences'));
    final currency = result['currencyCode'];
    if (currency != null &&
        (currency is! String ||
            !const {
              'IDR',
              'USD',
              'SGD',
              'MYR',
              'THB',
              'JPY',
            }.contains(currency))) {
      throw const BackupValidationException('Currency tidak didukung.');
    }
    final weekday = result['firstWeekday'];
    if (weekday != null &&
        weekday != DateTime.monday &&
        weekday != DateTime.sunday) {
      throw const BackupValidationException('Awal minggu tidak valid.');
    }
    final theme = result['themeMode'];
    if (theme != null &&
        (theme is! String ||
            !const {'system', 'light', 'dark'}.contains(theme))) {
      throw const BackupValidationException('Mode tema tidak valid.');
    }
    final showMoney = result['showMoneyValues'];
    if (showMoney != null && showMoney is! bool) {
      throw const BackupValidationException('Preferensi privasi tidak valid.');
    }
    return result;
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

  static bool _bool(Object? value, String field) {
    if (value is! bool) {
      throw BackupValidationException('$field harus berupa boolean.');
    }
    return value;
  }

  static bool _optionalBool(Object? value, String field) {
    if (value == null) return false;
    return _bool(value, field);
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

  static DateTime? _nullableDate(Object? value, String field) {
    if (value == null) return null;
    return _date(value, field);
  }
}
