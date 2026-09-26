import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/features/shell/app_shell.dart' show focusTargetIn, topLeftFocusable;

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

  testWidgets('focusTargetIn follows remembered scopes and never returns a bare one', (tester) async {
    final body = FocusScopeNode(debugLabel: 'body');
    final page = FocusScopeNode(debugLabel: 'page');
    final field = FocusNode(debugLabel: 'field');
    final card = FocusNode(debugLabel: 'card');
    addTearDown(() {
      for (final n in [body, page, field, card]) {
        n.dispose();
      }
    });
    await tester.pumpWidget(MaterialApp(
      home: FocusScope(
        node: body,
        child: FocusScope(
          node: page,
          child: Column(
            children: [
              TextButton(focusNode: field, onPressed: () {}, child: const Text('field')),
              TextButton(focusNode: card, onPressed: () {}, child: const Text('card')),
            ],
          ),
        ),
      ),
    ));
    card.requestFocus();
    await tester.pump();
    // Back from the tab bar: the card the page remembers, through the page's own scope.
    expect(focusTargetIn(body), card);
    // What a text field does when the keyboard closes (Sentry FLUTTER-1W): the page scope is left
    // holding the focus with nothing remembered.
    card.unfocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, page);
    expect(focusTargetIn(body), field);
    expect(focusTargetIn(page), field);
  });
}
