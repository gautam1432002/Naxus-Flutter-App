// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:nexus/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    // Mock screen size to avoid flex overflows in mobile layout
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // Mock env vars for test
    dotenv.loadFromString(envString: 'NASA_API_KEY=test\nOPENWEATHER_API_KEY=test');
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NexusApp());

    expect(find.byType(NexusApp), findsOneWidget);
  });
}
