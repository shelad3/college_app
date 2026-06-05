import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_app/providers/app_state.dart';
import 'package:college_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..initMockData(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('College Portal'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
