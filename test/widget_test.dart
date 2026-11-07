import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_incident_reporting_app/app/theme/app_theme.dart';
import 'package:campus_incident_reporting_app/core/constants/app_strings.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_controller.dart';
import 'package:campus_incident_reporting_app/features/authentication/application/auth_state.dart';
import 'package:campus_incident_reporting_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:campus_incident_reporting_app/features/authentication/presentation/screens/register_screen.dart';
import 'package:campus_incident_reporting_app/features/shell/presentation/initial_shell_screen.dart';
import 'package:campus_incident_reporting_app/shared/widgets/brand_logo.dart';
import 'package:campus_incident_reporting_app/shared/widgets/status_badge.dart';

class MockAuthController extends AuthController {
  @override
  AuthState build() {
    return AuthState.unauthenticated();
  }
}

void main() {
  testWidgets('Initial application shell renders branding and status tokens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const InitialShellScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.byType(BrandLogo), findsNWidgets(2));
    expect(find.byType(StatusBadge), findsNWidgets(5));
    expect(find.text('Foundation Initialized'), findsOneWidget);
  });

  testWidgets('LoginScreen renders ALU authentication fields and actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(MockAuthController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('ALU Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with ALU Google'), findsOneWidget);
    expect(find.text('Register here'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders student registration form and ALU domain notice',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(MockAuthController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Registration'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Student Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Student Account'), findsOneWidget);
  });
}
