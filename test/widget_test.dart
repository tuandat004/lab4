import 'package:contacts_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - no Firebase error', (WidgetTester tester) async {
    // MyApp with firebaseError = null simulates successful Firebase init
    // CheckUser will be shown (it handles auth routing internally)
    await tester.pumpWidget(
      const MyApp(firebaseError: null),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
