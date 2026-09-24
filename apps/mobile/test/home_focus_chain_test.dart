import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/widgets/row_focus_chain.dart';

/// Home page rows as the remote sees them: hero, an empty conditional shelf, two shelves, footer.
void main() {
  late FocusScopeNode hero, emptyShelf, shelfA, shelfB;
  late FocusNode footer;
  final nodes = <String, FocusNode>{};

  Widget button(String id) => TextButton(focusNode: nodes.putIfAbsent(id, () => FocusNode(debugLabel: id)), onPressed: () {}, child: Text(id));

  Widget row(FocusScopeNode scope, List<String> ids) => FocusScope(node: scope, child: Row(children: [for (final id in ids) button(id)]));

  setUp(() {
    nodes.clear();
    hero = FocusScopeNode(debugLabel: 'hero');
    emptyShelf = FocusScopeNode(debugLabel: 'empty');
    shelfA = FocusScopeNode(debugLabel: 'a');
    shelfB = FocusScopeNode(debugLabel: 'b');
    footer = FocusNode(debugLabel: 'footer');
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RowFocusChain(
          name: 'test-chain',
          rows: [hero, emptyShelf, shelfA, shelfB, footer],
          isolated: {footer},
          child: Column(
            children: [
              row(hero, ['play', 'info']),
              FocusScope(node: emptyShelf, child: const SizedBox(height: 40)),
              row(shelfA, ['a1', 'a2', 'a3']),
              // Much shorter row, like Recent channels between poster shelves.
              row(shelfB, ['b1', 'b2']),
              Row(children: [const Spacer(), TextButton(focusNode: footer, onPressed: () {}, child: const Text('footer'))]),
            ],
          ),
        ),
      ),
    ));
    nodes['play']!.requestFocus();
    await tester.pump();
  }

  Future<String?> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump(const Duration(milliseconds: 300));
    return FocusManager.instance.primaryFocus?.debugLabel;
  }

  testWidgets('Down walks every non-empty row in order, then stays on the footer', (tester) async {
    await pump(tester);
    expect(await press(tester, LogicalKeyboardKey.arrowDown), 'a1');
    expect(await press(tester, LogicalKeyboardKey.arrowDown), 'b1');
    expect(await press(tester, LogicalKeyboardKey.arrowDown), 'footer');
    expect(await press(tester, LogicalKeyboardKey.arrowDown), 'footer');
  });

  testWidgets('Up walks back and each row remembers its card', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowRight); // info
    await press(tester, LogicalKeyboardKey.arrowDown); // a1
    await press(tester, LogicalKeyboardKey.arrowRight); // a2
    await press(tester, LogicalKeyboardKey.arrowDown); // b1
    expect(await press(tester, LogicalKeyboardKey.arrowDown), 'footer');
    expect(await press(tester, LogicalKeyboardKey.arrowUp), 'b1');
    expect(await press(tester, LogicalKeyboardKey.arrowUp), 'a2');
    expect(await press(tester, LogicalKeyboardKey.arrowUp), 'info');
  });

  testWidgets('Left/Right never leave the footer, and stay inside a shelf', (tester) async {
    await pump(tester);
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(await press(tester, LogicalKeyboardKey.arrowLeft), 'footer');
    expect(await press(tester, LogicalKeyboardKey.arrowUp), 'b1');
    expect(await press(tester, LogicalKeyboardKey.arrowLeft), 'b1');
  });
}
