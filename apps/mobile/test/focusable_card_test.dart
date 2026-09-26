import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/app/responsive.dart';
import 'package:multiptv/widgets/focusable_card.dart';

/// `InkWell.onLongPress` only ever fires from a touch gesture: a remote has no equivalent, so a
/// held OK stands in for it (Sentry: no D-pad way to favourite a live channel).
void main() {
  var taps = 0;
  var longPresses = 0;
  late FocusNode node;

  setUp(() {
    taps = 0;
    longPresses = 0;
    node = FocusNode(debugLabel: 'card');
  });
  tearDown(() => node.dispose());

  Future<void> pump(WidgetTester tester, {VoidCallback? onLongPress}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [performanceModeProvider.overrideWithValue(false)],
      child: MaterialApp(
        home: Scaffold(
          body: FocusableCard(
            focusNode: node,
            autofocus: true,
            onTap: () => taps++,
            onLongPress: onLongPress ?? () => longPresses++,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a short OK press taps, not a long press', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 1);
    expect(longPresses, 0);
  });

  testWidgets('OK held past the threshold long-presses once, not a tap on release', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(okHoldDuration + const Duration(milliseconds: 10));
    expect(longPresses, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 0);
    expect(longPresses, 1);
  });

  testWidgets('repeats while held do not each fire a tap', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 1);
    expect(longPresses, 0);
  });

  testWidgets('without onLongPress, OK behaves exactly like a plain activation (single tap)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [performanceModeProvider.overrideWithValue(false)],
      child: MaterialApp(
        home: Scaffold(
          body: FocusableCard(focusNode: node, autofocus: true, onTap: () => taps++, child: const SizedBox(width: 100, height: 100)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 1);
  });
}
