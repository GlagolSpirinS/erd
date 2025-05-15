import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erd/main.dart';
import 'package:erd/login_screen.dart';
import 'package:erd/charts_widget.dart';

void main() {
  group('Login Screen Tests', () {
    testWidgets('Login screen should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      expect(find.text('Вход в систему'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Login fields validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Find text fields
      final loginField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      // Test empty fields
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Should show validation messages
      expect(find.text('Введите логин'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);

      // Test with invalid login
      await tester.enterText(loginField, 'inv');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Логин должен быть не менее 3 символов'), findsOneWidget);
    });
  });

  group('Charts Widget Tests', () {
    testWidgets('Charts widget should render', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChartsWidget(),
        ),
      ));

      expect(find.byType(ChartsWidget), findsOneWidget);
    });
  });
} 