import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/app.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HimatchApp(),
      ),
    );

    // Verify app title is shown
    expect(find.text('Himatch'), findsOneWidget);
  });
}
