import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../services/privacy_service.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../main/money_controller.dart';
import 'account_detail_view.dart';
import 'account_form_sheet.dart';

class AccountsView extends GetView<MoneyController> {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = Get.find<PrivacyService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Akun Saya')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Akun',
        onPressed: () => showAccountForm(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        final visible = privacy.showMoney.value;
        if (controller.accounts.isEmpty) {
          return EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Belum ada akun',
            message:
                'Tambahkan tempat kamu menyimpan uang untuk mulai mencatat.',
            action: FilledButton.icon(
              onPressed: () => showAccountForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Akun'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            100,
          ),
          children: [
            FerikCard(
              color: context.ferikColors.primaryContainer,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Uang',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          height: 36,
                          child: MoneyText(
                            amount: controller.totalBalance,
                            visible: visible,
                            scaleDown: true,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: visible
                        ? 'Sembunyikan nominal'
                        : 'Tampilkan nominal',
                    onPressed: privacy.toggleMoneyVisibility,
                    icon: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Semua Akun'),
            const SizedBox(height: AppSpacing.xs),
            ...controller.activeAccounts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: FerikCard(
                  padding: EdgeInsets.zero,
                  onTap: () => Get.to(
                    () => AccountDetailView(accountId: item.account.id),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.ferikColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            iconForName(item.account.icon),
                            color: context.ferikColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                _typeLabel(item.account.type),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox(
                          width:
                              MediaQuery.sizeOf(
                                context,
                              ).width.clamp(320.0, 480.0) *
                              0.28,
                          child: MoneyText(
                            amount: item.balance,
                            visible: visible,
                            scaleDown: true,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.ferikColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (controller.accounts.any((item) => item.account.isArchived)) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Diarsipkan'),
              const SizedBox(height: AppSpacing.xs),
              ...controller.accounts
                  .where((item) => item.account.isArchived)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: FerikCard(
                        onTap: () => Get.to(
                          () => AccountDetailView(accountId: item.account.id),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.archive_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(item.account.name)),
                            MoneyText(
                              amount: item.balance,
                              visible: visible,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        );
      }),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'bank' => 'Bank',
    'ewallet' => 'E-wallet',
    'savings' => 'Tabungan',
    'other' => 'Lainnya',
    _ => 'Tunai',
  };
}
