import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/trace_tag.dart';

void main() {
  testWidgets('pathOf names the tagged row, the list index and the node', (tester) async {
    final nodes = List.generate(5, (i) => FocusNode());
    final named = TraceTag.name(FocusNode(), 'play');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TraceTag('home', child: Column(children: [
          TraceTag('hero', child: TextButton(focusNode: named, onPressed: () {}, child: const Text('play'))),
          TraceTag('new-movies', child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, i) => TextButton(focusNode: nodes[i], onPressed: () {}, child: Text('$i')),
            ),
          )),
        ])),
      ),
    ));
    expect(TraceTag.pathOf(nodes[2]), 'home/new-movies/h#2');
    expect(TraceTag.pathOf(named), 'home/hero/play');
  });
}
