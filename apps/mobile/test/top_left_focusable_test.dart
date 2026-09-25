import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/features/shell/app_shell.dart' show topLeftFocusable;

void main() {
  testWidgets('topLeftFocusable skips nested scopes and returns their first button', (tester) async {
    final body = FocusScopeNode(debugLabel: 'body');
    final hero = FocusScopeNode(debugLabel: 'hero');
    final play = FocusNode(debugLabel: 'play');
    final below = FocusNode(debugLabel: 'below');
    addTearDown(() {
      for (final n in [body, hero, play, below]) {
        n.dispose();
      }
    });
    await tester.pumpWidget(MaterialApp(
      home: FocusScope(
        node: body,
        child: Column(
          children: [
            // The hero scope starts at the very top-left, above and left of its own button.
            FocusScope(
              node: hero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 0, 0),
                child: TextButton(focusNode: play, onPressed: () {}, child: const Text('play')),
              ),
            ),
            TextButton(focusNode: below, onPressed: () {}, child: const Text('below')),
          ],
        ),
      ),
    ));
    expect(topLeftFocusable(body), play);
  });
}
