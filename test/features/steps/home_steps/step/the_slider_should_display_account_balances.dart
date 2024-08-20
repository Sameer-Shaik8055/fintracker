import 'package:flutter_test/flutter_test.dart';

/// Usage: the slider should display account balances
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintracker/screens/home/home.screen.dart';
Future<void> theSliderShouldDisplayAccountBalances(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.text('\$1000.00'), findsOneWidget);
  expect(find.text('\$2000.00'), findsOneWidget);
  expect(find.text('\$3000.00'), findsOneWidget);
}
