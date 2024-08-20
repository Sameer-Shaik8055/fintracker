import 'package:flutter_test/flutter_test.dart';

/// Usage: the slider should show account holder names
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintracker/screens/home/home.screen.dart';
Future<void> theSliderShouldShowAccountHolderNames(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.text('John Doe'), findsOneWidget);
  expect(find.text('Jane Doe'), findsOneWidget);
  expect(find.text('John Smith'), findsOneWidget);
}