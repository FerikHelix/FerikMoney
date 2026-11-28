import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/l10n.dart';
import 'wallet_editor.dart';

class WalletFormScreen extends ConsumerStatefulWidget {
  const WalletFormScreen({this.walletId, super.key});

  final int? walletId;

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _editorKey = GlobalKey<WalletEditorState>();
  bool _dirty = false;
  bool _saving = false;
  bool _saved = false;

  bool get _isEditing => widget.walletId != null;

  Future<void> _save() async {
    final editor = _editorKey.currentState;
    if (editor == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await editor.save();
      if (!mounted) {
        return;
      }
      if (ok) {
        _saved = true;
        showSavedMessage(context, context.l10n.walletSaved);
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return _buildScaffold(null);
    }
    final wallet = ref.watch(walletProvider(widget.walletId!));
    return wallet.when(
      data: (value) => value == null
          ? Scaffold(body: Center(child: Text(context.l10n.loadFailed)))
          : _buildScaffold(value),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text(context.l10n.loadFailed))),
    );
  }

  Widget _buildScaffold(Wallet? wallet) {
    return DirtyPopScope(
      dirty: _dirty && !_saved,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? context.l10n.editWallet : context.l10n.newWallet,
          ),
        ),
        body: WalletEditor(
          key: _editorKey,
          wallet: wallet,
          onDirtyChanged: (dirty) => setState(() => _dirty = dirty),
        ),
        bottomNavigationBar: SaveBar(
          label: context.l10n.save,
          onPressed: _save,
          isSaving: _saving,
        ),
      ),
    );
  }
}
