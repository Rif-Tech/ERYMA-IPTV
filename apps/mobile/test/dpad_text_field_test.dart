import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/widgets/dpad_text_field.dart';

/// The remote-friendly bits of DpadTextField.keyHandler: Down leaves the field for a target of the
/// caller's choosing instead of moving the text cursor, and OK opens the keyboard on a field that
/// has focus but no keyboard showing (a plain TextField only ever opens it from a touch/mouse tap).
/// Returning the focus to the field once its keyboard closes relies on RemoteKeyTracker's live key
/// tracking and is exercised on-device (README/roadmap), not here.
void main() {
  testWidgets('Down calls onDown instead of moving the text cursor', (tester) async {
    var downCalls = 0;
    final target = FocusNode(debugLabel: 'target');
    addTearDown(target.dispose);
    final fieldFocus = FocusNode(
      debugLabel: 'field',
      onKeyEvent: DpadTextField.keyHandler(onDown: () {
        downCalls++;
        target.requestFocus();
        return true;
      }),
    );
    addTearDown(fieldFocus.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          DpadTextField(focusNode: fieldFocus, autofocus: true),
          TextButton(focusNode: target, onPressed: () {}, child: const Text('target')),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(fieldFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(downCalls, 1);
    expect(target.hasFocus, isTrue);
  });

  testWidgets('without onDown, Down is left for normal traversal (moves the cursor, does not throw)', (tester) async {
    final fieldFocus = FocusNode(debugLabel: 'field', onKeyEvent: DpadTextField.keyHandler());
    addTearDown(fieldFocus.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DpadTextField(focusNode: fieldFocus, autofocus: true))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(fieldFocus.hasFocus, isTrue);
  });

  testWidgets('OK opens the keyboard on a focused field with none showing', (tester) async {
    final fieldFocus = FocusNode(debugLabel: 'field', onKeyEvent: DpadTextField.keyHandler());
    addTearDown(fieldFocus.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DpadTextField(focusNode: fieldFocus, autofocus: true))));
    await tester.pumpAndSettle();
    // autofocus opened the keyboard already; close it the way DpadTextField's own "keep focus"
    // handling assumes the platform does (the field stays focused, no keyboard shown).
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
