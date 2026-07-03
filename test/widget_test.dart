import 'package:flutter_test/flutter_test.dart';
import 'package:madrasa_app/app.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MadrasaApp());
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
