import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/widgets/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              context.l10n.theme,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (value) => _set(ref, value),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(context.l10n.themeSystem),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(context.l10n.themeLight),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(context.l10n.themeDark),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.storage_rounded),
            title: Text(context.l10n.dataStoredLocally),
          ),
          ListTile(
            leading: const Icon(Symbols.info_rounded),
            title: Text(context.l10n.about),
            subtitle: Text(context.l10n.versionLabel('1.0.0')),
          ),
        ],
      ),
    );
  }

  void _set(WidgetRef ref, ThemeMode? mode) {
    if (mode != null) {
      ref.read(themeModeControllerProvider).setMode(mode);
    }
  }
}
