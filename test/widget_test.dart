import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuet_dsw_app/main.dart';
import 'package:cuet_dsw_app/screens/character_certificate_screen.dart';
import 'package:cuet_dsw_app/screens/home_screen.dart';

void main() {
  testWidgets('app shows the splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const CUETDSWApp());

    expect(find.text('CUET DSW Smart Service'), findsOneWidget);
    expect(find.text("Directorate of Students' Welfare"), findsOneWidget);
  });

  testWidgets('home service card navigates to certificate form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.widgetWithText(Card, 'Character Certificate'));
    await tester.pumpAndSettle();

    expect(find.byType(CharacterCertificateScreen), findsOneWidget);
  });
}
