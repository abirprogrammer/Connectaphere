import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectsphere/main.dart';

void main() {
  testWidgets('ConnectSphere app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ConnectSphereApp()));

    // Verify login screen or app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
