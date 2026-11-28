import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Indonesian copy has no exclamation marks or emoji', () {
    final file = File('lib/l10n/app_id.arb');
    expect(file.existsSync(), isTrue);
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final emoji = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );

    for (final entry in data.entries) {
      if (entry.key.startsWith('@') || entry.value is! String) {
        continue;
      }
      final value = entry.value! as String;
      expect(value.contains('!'), isFalse, reason: entry.key);
      expect(emoji.hasMatch(value), isFalse, reason: entry.key);
      expect(value, value.trim(), reason: entry.key);
    }
  });
}
