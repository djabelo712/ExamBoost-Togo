// test/widget_test.dart
// Basic smoke test that does NOT depend on the app's main entry point
// (which requires Hive initialization + the generated .g.dart adapters).
//
// We simply pump a trivial MaterialApp and verify that text renders.
// Real smoke tests of the app are in test/integration/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trivial smoke test: a Text widget renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('ExamBoost Togo smoke test'),
        ),
      ),
    );

    expect(find.text('ExamBoost Togo smoke test'), findsOneWidget);
  });
}
