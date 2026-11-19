import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuet_dsw_app/screens/home_screen.dart';
import 'package:cuet_dsw_app/screens/splash_screen.dart';

void main() {
  testWidgets('splash screen shows the app identity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('CUET DSW Smart Service'), findsOneWidget);
    expect(find.text("Directorate of Students' Welfare"), findsOneWidget);
  });

  testWidgets('home screen shows the character certificate service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.widgetWithText(Card, 'Character Certificate'), findsOneWidget);
  });
}
