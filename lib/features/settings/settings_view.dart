import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/design_tokens.dart';
import '../../models/backup_data.dart';
import '../../services/backup_service.dart';
import '../../services/privacy_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/ferik_card.dart';
import 'categories_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _export(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: const Text('Simpan file JSON'),
                onTap: () => Navigator.pop(context, 'save'),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Bagikan backup'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;
    try {
      final service = Get.find<BackupService>();
      if (action == 'save') {
        final path = await service.saveBackup();
        if (path != null) {
          Get.snackbar('Export selesai', 'Backup JSON berhasil disimpan.');
        }
      } else {
        await service.shareBackup();
      }
    } catch (_) {
      Get.snackbar(
        'Export gagal',
        'Backup tidak dapat dibuat atau disimpan.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final service = Get.find<BackupService>();
      final backup = await service.pickAndValidateBackup();
      if (backup == null || !context.mounted) return;
      final confirmed = await _confirmRestore(context, backup);
      if (!confirmed) return;
      await service.restore(backup);
      Get.snackbar(
        'Restore selesai',
        'Data FerikMoney berhasil dipulihkan.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on BackupValidationException catch (error) {
      Get.snackbar('Backup tidak valid', error.message);
    } catch (_) {
      Get.snackbar(
        'Import gagal',
        'Data lama tetap aman. Periksa file lalu coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _confirmRestore(BuildContext context, BackupData backup) async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    final privacy = Get.find<PrivacyService>();
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
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Kelola Kategori'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Get.to(() => const CategoriesView()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('Simpan atau bagikan backup JSON'),
                  onTap: () => _export(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import Data'),
                  subtitle: const Text('Pulihkan dari backup FerikMoney'),
                  onTap: () => _import(context),
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
