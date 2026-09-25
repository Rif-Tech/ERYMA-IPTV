import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/widgets/row_focus_chain.dart';

/// Page of 300 px sections in a 600 px screen, like home rows below the hero.
void main() {
  final keys = List.generate(6, (_) => GlobalKey());

  Future<ScrollPosition> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ListView(children: [for (final k in keys) SizedBox(key: k, height: 300)]),
    ));
    return tester.state<ScrollableState>(find.byType(Scrollable)).position;
  }

  testWidgets('a partly visible section is scrolled just enough to show it whole', (tester) async {
    final position = await pump(tester);
    // Section 1 spans 300-600: its bottom margin is cut, so scroll by the margin only.
    revealSection(keys[1].currentContext!);
    await tester.pumpAndSettle();
    expect(position.pixels, 24);
    // Section 2 (600-900) is below the screen: its bottom lands at the screen bottom, not centred.
    revealSection(keys[2].currentContext!);
    await tester.pumpAndSettle();
    expect(position.pixels, 900 + 24 - 600);
  });

  testWidgets('a fully visible section never moves the page (Left/Right inside a row)', (tester) async {
    final position = await pump(tester);
    position.jumpTo(250);
    await tester.pump();
    revealSection(keys[1].currentContext!); // 300-600 within 250-850
    await tester.pumpAndSettle();
    expect(position.pixels, 250);
  });

  testWidgets('going back up aligns the section top, with a margin', (tester) async {
    final position = await pump(tester);
    position.jumpTo(900);
    await tester.pump();
    revealSection(keys[2].currentContext!); // 600-900, above the screen
    await tester.pumpAndSettle();
    expect(position.pixels, 600 - 24);
  });

  testWidgets('revealInRow scrolls a row just enough for an off-screen card', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cards = List.generate(10, (_) => GlobalKey());
    await tester.pumpWidget(MaterialApp(
      home: ListView(scrollDirection: Axis.horizontal, children: [for (final k in cards) SizedBox(key: k, width: 200)]),
    ));
    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    // Card 3 spans 600-800: already visible, nothing moves.
    revealInRow(cards[3].currentContext!);
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
    // Card 5 spans 1000-1200: its right edge lands on the screen edge.
    revealInRow(cards[5].currentContext!);
    await tester.pumpAndSettle();
    expect(position.pixels, 1200 - 800);
    // Back to card 1 (200-400): its left edge lands on the screen edge.
    revealInRow(cards[1].currentContext!);
    await tester.pumpAndSettle();
    expect(position.pixels, 200);
  });
}
