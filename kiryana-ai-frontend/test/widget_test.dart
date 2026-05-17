import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiryana_ai/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KiryanaAIApp());
    expect(find.byType(MaterialApp), findsNothing); // GoRouter uses MaterialApp.router
  });
}
