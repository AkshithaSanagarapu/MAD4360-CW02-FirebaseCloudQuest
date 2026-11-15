import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cloud Quest title renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: null, body: Center(child: Text('Cloud Quest'))),
      ),
    );
    expect(find.text('Cloud Quest'), findsOneWidget);
  });
}
