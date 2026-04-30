import 'package:flutter_test/flutter_test.dart';

import 'package:bildunya_frontend/main.dart';

void main() {
  testWidgets('Splash shows BilDünya branding', (WidgetTester tester) async {
    await tester.pumpWidget(const BilDunyaApp());

    expect(find.text('BilDünya'), findsOneWidget);
    expect(find.text('THE MIDNIGHT NAVIGATOR'), findsOneWidget);
    expect(find.text('Keşfetmeye Başla'), findsOneWidget);
  });
}
