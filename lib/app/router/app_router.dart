import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/application/auth_state.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/staff_unauthorized_screen.dart';
import '../../features/authentication/presentation/screens/verify_email_screen.dart';
import '../../features/dashboard/presentation/staff/staff_dashboard_screen.dart';
import '../../features/dashboard/presentation/student/student_home_screen.dart';
import '../../features/shell/presentation/initial_shell_screen.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Allow initial session loading to complete
      if (authState.status == AuthStatus.initial) {
        return null;
      }

      final isAuthRoute = loc == '/login' || loc == '/register';

      switch (authState.status) {
        case AuthStatus.unauthenticated:
          if (!isAuthRoute && loc != '/foundation') {
            return '/login';
          }
          return null;

        case AuthStatus.unverified:
          if (loc != '/verify-email') {
            return '/verify-email';
          }
          return null;

        case AuthStatus.staffPendingApproval:
          if (loc != '/staff-unauthorized') {
            return '/staff-unauthorized';
          }
          return null;

        case AuthStatus.authenticatedStudent:
          if (isAuthRoute || loc == '/verify-email' || loc == '/staff-unauthorized' || loc == '/') {
            return '/student';
          }
          return null;

        case AuthStatus.authenticatedStaff:
          if (isAuthRoute || loc == '/verify-email' || loc == '/staff-unauthorized' || loc == '/') {
            return '/staff';
          }
          return null;

        case AuthStatus.initial:
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/staff-unauthorized',
        name: 'staffUnauthorized',
        builder: (context, state) => const StaffUnauthorizedScreen(),
      ),
      GoRoute(
        path: '/student',
        name: 'studentHome',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/staff',
        name: 'staffDashboard',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/foundation',
        name: 'foundation',
        builder: (context, state) => const InitialShellScreen(),
      ),
    ],
  );
});
