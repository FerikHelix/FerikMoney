import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../db/database.dart';
import '../models/models.dart';
import '../money/rupiah.dart';
import '../money/rupiah_input_formatter.dart';
import 'display.dart';
import 'format.dart';
import 'l10n.dart';

class RupiahField extends StatelessWidget {
  const RupiahField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: const [RupiahInputFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        errorText: errorText,
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Symbols.calendar_today_rounded),
        ),
        child: Text(
          formatDateLabel(context, value),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class WalletDropdown extends StatelessWidget {
  const WalletDropdown({
    required this.wallets,
    required this.value,
    required this.onChanged,
    required this.label,
    this.errorText,
    super.key,
  });

  final List<Wallet> wallets;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected = value != null && wallets.any((w) => w.id == value);
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$value-${wallets.length}'),
      initialValue: selected ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        for (final wallet in wallets)
          DropdownMenuItem(
            value: wallet.id,
            child: Row(
              children: [
                WalletAvatar(
                  iconCodePoint: wallet.iconCodePoint,
                  colorValue: wallet.colorValue,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(wallet.name)),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
    required this.label,
    this.errorText,
    super.key,
  });

  final List<Category> categories;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected = value != null && categories.any((c) => c.id == value);
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$value-${categories.length}'),
      initialValue: selected ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        for (final category in categories)
          DropdownMenuItem(
            value: category.id,
            child: Row(
              children: [
                Icon(
                  symbolIcon(category.iconCodePoint),
                  color: Color(category.colorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(category.name)),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class NoteField extends StatelessWidget {
  const NoteField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: context.l10n.note,
        helperText: context.l10n.optional,
      ),
    );
  }
}

class WalletTypeChips extends StatelessWidget {
  const WalletTypeChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final WalletType value;
  final ValueChanged<WalletType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in WalletType.values)
          ChoiceChip(
            label: Text(walletTypeLabel(context, type)),
            avatar: Icon(walletTypeIcon(type), size: 18),
            selected: value == type,
            onSelected: (_) => onChanged(type),
          ),
      ],
    );
  }
}

int parseAmount(TextEditingController controller) =>
    parseRupiah(controller.text) ?? 0;
