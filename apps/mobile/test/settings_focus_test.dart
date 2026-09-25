import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/app/theme.dart';
import 'package:multiptv/features/settings/settings_tiles.dart';

void main() {
  // The focus highlight of a settings row is ink painted on SettingsSection's own Material, above
  // the glass panel: it must be the theme's focusColor, not the transparent tile colour.
  testWidgets('a focused tile in a SettingsSection paints the focus highlight', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(tv: true),
      home: Scaffold(
        body: ListView(children: [
          SettingsSection('Test', [
            ListTile(title: const Text('one'), onTap: () {}),
            ListTile(title: const Text('two'), onTap: () {}),
          ]),
        ]),
      ),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final ctx = FocusManager.instance.primaryFocus!.context!;
    expect(Material.of(ctx) as RenderObject, paints..rect(color: AppTheme.dark(tv: true).focusColor));
  });
}
