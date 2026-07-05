import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('欢迎登录'), findsOneWidget);
    expect(find.text('登 录'), findsOneWidget);
    expect(find.text('注册账号'), findsOneWidget);
  });
}
