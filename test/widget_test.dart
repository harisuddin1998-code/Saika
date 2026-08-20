import 'package:flutter_test/flutter_test.dart';

import 'package:saika/main.dart';

void main() {
  testWidgets('Splash screen shows brand and continue button', (WidgetTester tester) async {
    await tester.pumpWidget(const WoSafarApp());

    expect(find.text('Saika'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
