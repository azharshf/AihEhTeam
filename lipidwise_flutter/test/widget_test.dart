// Basic smoke test for LipidWise AI. This replaces the unused default
// Flutter counter-app template, which referenced a `MyApp`/counter widget
// that was never part of this project.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lipidwise_flutter/screens/landing_screen.dart';

void main() {
  testWidgets('LandingScreen shows role selection entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to LipidWise AI'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Doctor Portal Login'), findsOneWidget);
  });
}
