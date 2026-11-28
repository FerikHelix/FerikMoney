import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/db/errors.dart';
import '../../../core/models/models.dart';
import '../../../core/money/rupiah.dart';
import '../../../core/widgets/display.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/l10n.dart';

class WalletEditor extends ConsumerStatefulWidget {
  const WalletEditor({this.wallet, this.onDirtyChanged, super.key});

  final Wallet? wallet;
  final ValueChanged<bool>? onDirtyChanged;

  @override
  ConsumerState<WalletEditor> createState() => WalletEditorState();
}

class WalletEditorState extends ConsumerState<WalletEditor> {
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late WalletType _type;
  late int _icon;
  late int _color;
  String? _nameError;
  String? _amountError;
  bool _dirty = false;

  static const _icons = <IconData>[
    Symbols.payments_rounded,
    Symbols.account_balance_rounded,
    Symbols.account_balance_wallet_rounded,
    Symbols.savings_rounded,
    Symbols.credit_card_rounded,
    Symbols.smartphone_rounded,
    Symbols.storefront_rounded,
    Symbols.business_center_rounded,
    Symbols.home_rounded,
    Symbols.favorite_rounded,
  ];

  static const _colors = <int>[
    0xFF006C4C,
    0xFF1565C0,
    0xFF6A1B9A,
    0xFFC62828,
    0xFFEF6C00,
    0xFF00838F,
    0xFF4E342E,
    0xFF455A64,
  ];

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _name = TextEditingController(text: wallet?.name ?? '');
    _opening = TextEditingController(
      text: wallet == null ? '' : formatGrouped(wallet.openingBalance),
    );
    _type = wallet == null ? WalletType.cash : WalletType.parse(wallet.type);
    _icon = wallet?.iconCodePoint ?? Symbols.payments_rounded.codePoint;
    _color = wallet?.colorValue ?? _colors.first;
    _name.addListener(_markDirty);
    _opening.addListener(_markDirty);
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_dirty) {
      return;
    }
    _dirty = true;
    widget.onDirtyChanged?.call(true);
  }

  bool validate() {
    var valid = true;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _nameError = context.l10n.walletNameRequired;
      valid = false;
    } else {
      _nameError = null;
    }
    final amount = parseRupiah(_opening.text) ?? 0;
    if (amount > maxTransactionAmount) {
      _amountError = context.l10n.amountTooLarge;
      valid = false;
    } else {
      _amountError = null;
    }
    setState(() {});
    return valid;
  }

  Future<bool> save() async {
    if (!validate()) {
      return false;
    }
    final database = ref.read(databaseProvider);
    try {
      if (widget.wallet == null) {
        await database.walletDao.createWallet(
          name: _name.text,
          type: _type,
          openingBalance: parseRupiah(_opening.text) ?? 0,
          iconCodePoint: _icon,
          colorValue: _color,
        );
      } else {
        await database.walletDao.updateWallet(
          id: widget.wallet!.id,
          name: _name.text,
          type: _type,
          openingBalance: parseRupiah(_opening.text) ?? 0,
          iconCodePoint: _icon,
          colorValue: _color,
        );
      }
      _nameError = null;
      return true;
    } on DomainError catch (error) {
      if (error.code == ErrorCodes.duplicateName) {
        setState(() => _nameError = context.l10n.walletNameDuplicate);
      } else {
        rethrow;
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          autofocus: widget.wallet == null,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.walletName,
            errorText: _nameError,
          ),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.walletType, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        WalletTypeChips(
          value: _type,
          onChanged: (type) {
            setState(() {
              _type = type;
              _icon = walletTypeIcon(type).codePoint;
              _color = switch (type) {
                WalletType.cash => 0xFF2E7D32,
                WalletType.bank => 0xFF1565C0,
                WalletType.ewallet => 0xFF6A1B9A,
                WalletType.other => 0xFF455A64,
              };
            });
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        RupiahField(
          controller: _opening,
          label: context.l10n.openingBalance,
          errorText: _amountError,
        ),
        const SizedBox(height: 20),
        Text(context.l10n.iconLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final icon in _icons)
              InkWell(
                onTap: () {
                  setState(() => _icon = icon.codePoint);
                  _markDirty();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _icon == icon.codePoint
                        ? Color(_color).withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: _icon == icon.codePoint
                        ? Border.all(color: Color(_color), width: 2)
                        : null,
                  ),
                  child: Icon(icon, color: Color(_color)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(context.l10n.colorLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final color in _colors)
              InkWell(
                onTap: () {
                  setState(() => _color = color);
                  _markDirty();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: _color == color
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 2,
                          )
                        : null,
                  ),
                  child: _color == color
                      ? const Icon(
                          Symbols.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 96),
      ],
    );
  }
}
