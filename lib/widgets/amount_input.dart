import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../utils/money_formatter.dart';

class AmountInput extends StatefulWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.autofocus,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _focusNode.hasFocus
              ? colors.primary
              : context.ferikInteractiveBorder,
          width: _focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text('Nominal', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          TextField(
            key: const Key('transaction-amount-input'),
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            inputFormatters: [RupiahInputFormatter()],
            onChanged: widget.onChanged,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: 'Rp 0',
              hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colors.secondaryText.withValues(alpha: 0.65),
              ),
              prefixText: widget.controller.text.isEmpty ? null : 'Rp ',
              prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colors.mainText,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
