import 'package:flutter_test/flutter_test.dart';
import 'package:mohaseb_smart/main.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MohasebSmartApp());

    // Verify that the title and some key texts are present.
    expect(find.text('بقالة الأمل'), findsOneWidget);
    expect(find.text('ربحك اليوم'), findsOneWidget);
  });
}
