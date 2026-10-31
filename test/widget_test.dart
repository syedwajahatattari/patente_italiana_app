import 'package:flutter_test/flutter_test.dart';
import 'package:patente_italiana_app/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const PatenteItalianaApp());
    expect(find.byType(PatenteItalianaApp), findsOneWidget);
  });
}
