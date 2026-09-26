import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/app/responsive.dart';
import 'package:multiptv/widgets/shelf.dart';

/// A shelf far wider than a 960x540 TV screen, walked with the remote (Sentry FLUTTER-1Z/P: the
/// row never scrolled, the focused card sat off-screen and Right stopped working).
void main() {
  const gutter = 48.0;
  const screen = Size(960, 540);
  late List<FocusNode> nodes;

  setUp(() => nodes = List.generate(12, (i) => FocusNode(debugLabel: 'c$i')));
  tearDown(() {
    for (final n in nodes) {
      n.dispose();
    }
  });

  Future<ScrollPosition> pump(WidgetTester tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      // Low-end box: the smallest prefetch window, where a lagging row runs out of built cards.
      overrides: [performanceModeProvider.overrideWithValue(true)],
      child: MaterialApp(
        home: Scaffold(
          body: Shelf(
            title: 'Row',
            itemCount: nodes.length,
            itemWidth: 170,
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: gutter),
            itemBuilder: (_, i) => TextButton(focusNode: nodes[i], onPressed: () {}, child: Text('c$i')),
          ),
        ),
      ),
    ));
    nodes[0].requestFocus();
    await tester.pumpAndSettle();
    return tester.state<ScrollableState>(find.byType(Scrollable)).position;
  }

  int focused() => nodes.indexOf(FocusManager.instance.primaryFocus!);

  void expectShownInFull(int i) {
    final r = nodes[i].rect;
    expect(r.left, greaterThanOrEqualTo(gutter - 1), reason: 'c$i starts at ${r.left}');
    expect(r.right, lessThanOrEqualTo(screen.width - gutter + 1), reason: 'c$i ends at ${r.right}');
  }

  testWidgets('Right walks the whole row, each card shown in full inside the gutters', (tester) async {
    await pump(tester);
    for (var i = 1; i < nodes.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focused(), i);
      expectShownInFull(i);
    }
  });

  testWidgets('back to the first card, the row is at its start again', (tester) async {
    final position = await pump(tester);
    for (var i = 1; i < nodes.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(position.pixels, greaterThan(0));
    for (var i = 1; i < nodes.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(focused(), 0);
    expect(position.pixels, 0);
    expectShownInFull(0);
  });

  testWidgets('a held key keeps moving and the row keeps up', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focused(), 9);
    expectShownInFull(9);
  });

  // Left from the first card (Right from the last) used to fall through to the nearest focusable
  // *outside* the row — a page's back button, on the series detail screen (Sentry FLUTTER-2J).
  testWidgets('Left on the first card and Right on the last stay inside the row', (tester) async {
    final outside = FocusNode(debugLabel: 'outside');
    addTearDown(outside.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [performanceModeProvider.overrideWithValue(true)],
      child: MaterialApp(
        home: Scaffold(
          body: Row(children: [
            TextButton(focusNode: outside, onPressed: () {}, child: const Text('back')),
            Expanded(
              child: Shelf(
                title: 'Row',
                itemCount: nodes.length,
                itemWidth: 170,
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: gutter),
                itemBuilder: (_, i) => TextButton(focusNode: nodes[i], onPressed: () {}, child: Text('c$i')),
              ),
            ),
          ]),
        ),
      ),
    ));
    nodes[0].requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focused(), 0, reason: 'Left on the first card must not reach the back button outside the row');

    // Walk to the last card the same way every other test here does: requestFocus() alone cannot
    // reach an item the ListView has not built yet.
    for (var i = 1; i < nodes.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(focused(), nodes.length - 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focused(), nodes.length - 1, reason: 'Right on the last card must stay put');
  });
}
