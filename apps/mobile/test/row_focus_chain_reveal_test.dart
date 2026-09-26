import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/widgets/row_focus_chain.dart';

/// Home at start-up (Sentry FLUTTER-S): "Continue watching" finishes loading above the row the
/// user just moved to, which ended up under the screen.
void main() {
  testWidgets('the focused row is shown again when a row loads above it', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rows = List.generate(3, (i) => FocusScopeNode(debugLabel: 'row$i'));
    final cards = List.generate(3, (i) => FocusNode(debugLabel: 'card$i'));
    addTearDown(() {
      for (final n in [...rows, ...cards]) {
        n.dispose();
      }
    });
    var loaded = false;
    late StateSetter setState;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, set) {
        setState = set;
        return RowFocusChain(
          name: 'test-chain',
          rows: rows,
          // Same structure as home: one sliver per row, rows stay mounted when off-screen.
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                key: const ValueKey('row0'),
                child: FocusScope(node: rows[0], child: SizedBox(height: 250, child: TextButton(focusNode: cards[0], onPressed: () {}, child: const Text('0')))),
              ),
              if (loaded) const SliverToBoxAdapter(key: ValueKey('loaded'), child: SizedBox(height: 700)),
              for (var i = 1; i < 3; i++)
                SliverToBoxAdapter(
                  key: ValueKey('row$i'),
                  child: FocusScope(node: rows[i], child: SizedBox(height: 250, child: TextButton(focusNode: cards[i], onPressed: () {}, child: Text('$i')))),
                ),
            ],
          ),
        );
      }),
    ));
    cards[0].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, cards[1]);

    setState(() => loaded = true);
    await tester.pumpAndSettle();
    final r = cards[1].rect;
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(600));
  });
}
