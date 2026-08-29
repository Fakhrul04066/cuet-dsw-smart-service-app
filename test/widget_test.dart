import 'package:flutter_test/flutter_test.dart';

import 'package:cuet_dsw_app/main.dart';

void main() {
  testWidgets('app shows the splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const CUETDSWApp());

    expect(find.text('CUET DSW Smart Service'), findsOneWidget);
    expect(find.text("Directorate of Students' Welfare"), findsOneWidget);
  });
}
