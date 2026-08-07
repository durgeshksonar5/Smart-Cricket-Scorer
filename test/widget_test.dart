import 'package:flutter_test/flutter_test.dart';
import 'package:cricket/main.dart';
import 'package:cricket/screens/home_screen.dart';

void main() {
  testWidgets('CricketApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CricketApp());
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
