import 'package:flutter_test/flutter_test.dart';
import 'package:mohaseb_smart/main.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MohasebSmartApp());

    // Verify that the title is present.
    expect(find.text('المحاسب الذكي - الرئيسية'), findsOneWidget);
    expect(find.text('أهلاً بك في منصة المحاسب الذكي'), findsOneWidget);
  });
}
