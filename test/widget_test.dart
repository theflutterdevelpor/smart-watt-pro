import 'package:flutter_test/flutter_test.dart';
import 'package:smart_watt_pro/main.dart';

void main() {
  testWidgets('App starts without errors', (tester) async {
    await tester.pumpWidget(const SmartWattProApp());
    expect(find.byType(SmartWattProApp), findsOneWidget);
  });
}
