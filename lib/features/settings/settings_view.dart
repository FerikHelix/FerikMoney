import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../features/main/money_controller.dart';
import '../../models/backup_data.dart';
import '../../services/app_preferences_service.dart';
import '../../services/backup_service.dart';
import '../../services/currency_service.dart';
import '../../services/privacy_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  /// Small "save or share" chooser used by both JSON and CSV export.
  Future<String?> _chooseExportAction(
    BuildContext context, {
    required String saveLabel,
    required String shareLabel,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: Text(saveLabel),
                onTap: () => Navigator.pop(context, 'save'),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(shareLabel),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Blocks the screen with a spinner while [task] runs, so a slow backup or
  /// restore never looks frozen or gets tapped twice.
  Future<T> _withProgress<T>(BuildContext context, Future<T> Function() task) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Dialog(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text('Memproses...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return task().whenComplete(() {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _export(BuildContext context) async {
    final action = await _chooseExportAction(
      context,
      saveLabel: 'Simpan file JSON',
      shareLabel: 'Bagikan backup',
    );
    if (action == null || !context.mounted) return;
    try {
      final service = Get.find<BackupService>();
      if (action == 'save') {
        final path = await _withProgress(context, service.saveBackup);
        if (path != null) {
          showFeedback('Export selesai', 'Backup JSON berhasil disimpan.');
        }
      } else {
        await service.shareBackup();
      }
    } catch (_) {
      showFeedback('Export gagal', 'Backup tidak dapat dibuat atau disimpan.');
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final service = Get.find<BackupService>();
      final backup = await service.pickAndValidateBackup();
      if (backup == null || !context.mounted) return;
      final confirmed = await _confirmRestore(context, backup);
      if (!confirmed || !context.mounted) return;
      await _withProgress(context, () => service.restore(backup));
      showFeedback('Restore selesai', 'Data FerikMoney berhasil dipulihkan.');
    } on BackupValidationException catch (error) {
      showFeedback('Backup tidak valid', error.message);
    } catch (_) {
      showFeedback(
        'Import gagal',
        'Data lama tetap aman. Periksa file lalu coba lagi.',
      );
    }
  }

  Future<bool> _confirmRestore(BuildContext context, BackupData backup) async {
    final duplicate = Get.find<BackupService>().isDuplicateRestore(backup);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup: ${DateFormat('d MMMM yyyy', 'id_ID').format(backup.exportedAt)}',
            ),
            const SizedBox(height: 10),
            Text('${backup.accounts.length} Akun'),
            Text('${backup.categories.length} Kategori'),
            Text(
              '${NumberFormat.decimalPattern('id_ID').format(backup.transactions.length)} Transaksi',
            ),
            const SizedBox(height: 16),
            if (duplicate) ...[
              Text(
                'Backup ini sama dengan backup terakhir yang dipulihkan.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              'Data FerikMoney saat ini akan diganti dengan backup ini.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _exportCsv(BuildContext context) async {
    final action = await _chooseExportAction(
      context,
      saveLabel: 'Simpan CSV',
      shareLabel: 'Bagikan CSV',
    );
    if (action == null || !context.mounted) return;
    try {
      final service = Get.find<BackupService>();
      if (action == 'save') {
        final path = await _withProgress(context, service.saveCsv);
        if (path != null) {
          showFeedback('Export selesai', 'CSV berhasil disimpan.');
        }
      } else {
        await service.shareCsv();
      }
    } catch (_) {
      showFeedback('Export gagal', 'CSV transaksi tidak dapat dibuat.');
    }
  }

  Future<void> _chooseCurrency(BuildContext context) async {
    final database = Get.find<AppDatabase>();
    if (!await database.canChangeCurrency()) {
      showFeedback(
        'Currency terkunci',
        'Currency hanya dapat diganti sebelum ada saldo atau data finansial.',
      );
      return;
    }
    if (!context.mounted) return;
    final preferences = Get.find<AppPreferencesService>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Currency'),
        children: [
          RadioGroup<String>(
            groupValue: preferences.currencyCode.value,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: CurrencyService.supported
                  .map(
                    (item) => RadioListTile<String>(
                      value: item.code,
                      title: Text('${item.code} · ${item.symbol}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (value != null) await preferences.setCurrency(value);
  }

  Future<void> _reset(BuildContext context) async {
    while (true) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset semua data?'),
          content: const Text(
            'Akun, transaksi, budget, jadwal berulang, dan target tabungan akan dihapus permanen. Tema tetap dipertahankan.\n\nSaran: simpan backup dulu supaya data bisa dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Batal'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, 'backup'),
              child: const Text('Backup dulu'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, 'reset'),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (choice == 'backup') {
        await _export(context);
        if (!context.mounted) return;
        continue;
      }
      if (choice != 'reset') return;
      break;
    }
    await _withProgress(context, Get.find<BackupService>().resetData);
    showFeedback('Data direset', 'Kategori default telah dibuat kembali.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    final privacy = Get.find<PrivacyService>();
    final preferences = Get.find<AppPreferencesService>();
    final money = Get.find<MoneyController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          const _SectionLabel('Umum'),
          Obx(
            () => FerikCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Currency'),
                    subtitle: Text(preferences.currencyCode.value),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _chooseCurrency(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_view_week_outlined),
                    title: const Text('Awal minggu'),
                    trailing: DropdownButton<int>(
                      value: preferences.firstWeekday.value,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: DateTime.monday,
                          child: Text('Senin'),
                        ),
                        DropdownMenuItem(
                          value: DateTime.sunday,
                          child: Text('Minggu'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) preferences.setFirstWeekday(value);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Akun default'),
                    trailing: DropdownButton<String?>(
                      value:
                          money.activeAccounts.any(
                            (item) =>
                                item.account.id ==
                                preferences.defaultAccountId.value,
                          )
                          ? preferences.defaultAccountId.value
                          : null,
                      underline: const SizedBox.shrink(),
                      hint: const Text('Tidak ada'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tidak ada'),
                        ),
                        ...money.activeAccounts.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item.account.id,
                            child: Text(item.account.name),
                          ),
                        ),
                      ],
                      onChanged: preferences.setDefaultAccount,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Tampilan'),
          Obx(
            () => FerikCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tema', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Terang'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Gelap'),
                      ),
                    ],
                    selected: {theme.mode.value},
                    onSelectionChanged: (value) => theme.setMode(value.first),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      privacy.showMoney.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    title: const Text('Tampilkan nominal'),
                    subtitle: const Text('Berlaku di seluruh aplikasi'),
                    value: privacy.showMoney.value,
                    onChanged: (_) => privacy.toggleMoneyVisibility(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Data'),
          FerikCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Backup JSON'),
                  subtitle: const Text('Simpan atau bagikan backup JSON'),
                  onTap: () => _export(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('Export CSV'),
                  subtitle: const Text('Simpan atau bagikan transaksi'),
                  onTap: () => _exportCsv(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import Data'),
                  subtitle: const Text('Pulihkan dari backup FerikMoney'),
                  onTap: () => _import(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Reset Data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text('Hapus seluruh data finansial lokal'),
                  onTap: () => _reset(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Tentang'),
          FerikCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('FerikMoney'),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => Text(
                  snapshot.hasData
                      ? 'Versi ${snapshot.data!.version}'
                      : 'Versi 1.0.0',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Semua data keuangan tersimpan lokal di perangkat. FerikMoney tidak memakai iklan, analytics, atau akun online.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        0,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
