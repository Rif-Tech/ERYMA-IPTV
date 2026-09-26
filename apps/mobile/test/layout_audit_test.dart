import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/layout_audit.dart';

void main() {
  Future<List<Map<String, Object?>>> audit(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    return LayoutAudit.findings();
  }

  Widget zoomedArt({required bool clipped}) {
    // The blurred-poster backdrop: art zoomed x1.15 in a full-width frame (Sentry FLUTTER-1P).
    final art = Transform.scale(scale: 1.15, child: const SizedBox.expand(child: RawImage()));
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 960, height: 300, child: clipped ? ClipRect(child: art) : art),
    );
  }

  testWidgets('art zoomed inside a clip is not reported past the screen edge', (tester) async {
    expect(await audit(tester, zoomedArt(clipped: true)), isEmpty);
  });

  testWidgets('art really drawn past the screen edge is reported', (tester) async {
    final findings = await audit(tester, zoomedArt(clipped: false));
    expect(findings.map((f) => f['kind']), contains('offscreen_clip'));
  });

  Widget plot({required bool expected}) {
    final text = Text('word ' * 200, maxLines: 2, overflow: TextOverflow.ellipsis);
    return SizedBox(width: 300, child: expected ? TruncationExpected(child: text) : text);
  }

  testWidgets('a clamped teaser marked TruncationExpected is by design', (tester) async {
    expect(await audit(tester, plot(expected: true)), isEmpty);
  });

  testWidgets('an unmarked clamped text is reported as truncated', (tester) async {
    final findings = await audit(tester, plot(expected: false));
    expect(findings.map((f) => f['kind']), contains('text_truncated'));
  });
}
