import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders sign-in buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Himatch'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
    expect(find.text('Googleでサインイン'), findsOneWidget);
    expect(find.text('LINEでサインイン'), findsOneWidget);
    expect(find.text('デモモードで始める'), findsOneWidget);
  });
}
