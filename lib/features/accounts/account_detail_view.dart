import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../repositories/money_repository.dart';
import '../../services/app_preferences_service.dart';
import '../../services/privacy_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/account_icon_tile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_tile.dart';
import '../main/money_controller.dart';
import '../transactions/transaction_detail_sheet.dart';
import 'account_form_sheet.dart';

class AccountDetailView extends GetView<MoneyController> {
  const AccountDetailView({super.key, required this.accountId});

  final String accountId;

  /// Archiving is reversible, so it happens right away with an Undo.
  Future<void> _archive(String name, {required bool archived}) async {
    final repository = Get.find<MoneyRepository>();
    try {
      await repository.archiveAccount(accountId, archived: !archived);
      final preferences = Get.find<AppPreferencesService>();
      if (!archived && preferences.defaultAccountId.value == accountId) {
        await preferences.setDefaultAccount(null);
      }
      showFeedback(
        archived ? 'Akun dipulihkan' : 'Akun diarsipkan',
        archived
            ? '$name kembali tersedia untuk transaksi baru.'
            : '$name disembunyikan dari transaksi baru. Histori tetap aman.',
        duration: const Duration(seconds: 5),
        actionLabel: 'UNDO',
        onAction: () async {
          await repository.archiveAccount(accountId, archived: archived);
          Get.closeCurrentSnackbar();
        },
      );
    } on MoneyValidationException catch (error) {
      showFeedback('Akun tidak dapat diperbarui', error.message);
    } catch (_) {
      showFeedback('Terjadi kesalahan', 'Akun tidak dapat diperbarui.');
    }
  }

  /// Only offered for accounts without any transactions.
  Future<void> _delete(BuildContext context, String name) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Hapus akun?',
      message: '$name akan dihapus permanen. Akun ini belum punya transaksi.',
    );
    if (!confirmed) return;
    try {
      await Get.find<MoneyRepository>().deleteAccount(accountId);
      final preferences = Get.find<AppPreferencesService>();
      if (preferences.defaultAccountId.value == accountId) {
        await preferences.setDefaultAccount(null);
      }
      Get.back<void>();
      showFeedback('Akun dihapus', '$name telah dihapus.');
    } on MoneyValidationException catch (error) {
      showFeedback('Akun tidak dapat dihapus', error.message);
    } catch (_) {
      showFeedback('Terjadi kesalahan', 'Akun tidak dapat dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacy = Get.find<PrivacyService>();
    return Obx(() {
      final visible = privacy.showMoney.value;
      final item = controller.accountById(accountId);
      if (item == null) {
        return const Scaffold(
          body: EmptyState(
            icon: Icons.error_outline,
            title: 'Akun tidak ditemukan',
          ),
        );
      }
      final related = controller.transactions
          .where(
            (transaction) =>
                transaction.accountId == accountId ||
                transaction.destinationAccountId == accountId,
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(item.account.name),
          actions: [
            IconButton(
              tooltip: 'Edit Akun',
              onPressed: () => showAccountForm(context, account: item.account),
              icon: const Icon(Icons.edit_outlined),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: IconButton(
                tooltip: item.account.isArchived
                    ? 'Pulihkan Akun'
                    : 'Arsipkan Akun',
                onPressed: () => _archive(
                  item.account.name,
                  archived: item.account.isArchived,
                ),
                icon: Icon(
                  item.account.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            FerikCard(
              color: context.ferikColors.primaryContainer,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AccountIconTile(type: item.account.type, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Saat Ini',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        SizedBox(
                          height: 34,
                          child: MoneyText(
                            amount: item.balance,
                            visible: visible,
                            scaleDown: true,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Transaksi Akun'),
            const SizedBox(height: AppSpacing.xs),
            if (related.isEmpty) ...[
              const FerikCard(
                child: EmptyState(
                  compact: true,
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _delete(context, item.account.name),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus akun'),
              ),
            ] else
              FerikCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < related.length; index++)
                      TransactionTile(
                        transaction: related[index],
                        accountName:
                            controller
                                .accountById(related[index].accountId)
                                ?.account
                                .name ??
                            '-',
                        destinationName: controller
                            .accountById(related[index].destinationAccountId)
                            ?.account
                            .name,
                        category: controller.categoryById(
                          related[index].categoryId,
                        ),
                        dateLabel: relativeDateLabel(
                          related[index].transactionDate,
                        ),
                        visible: visible,
                        showDivider: index < related.length - 1,
                        onTap: () =>
                            showTransactionDetail(context, related[index]),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
