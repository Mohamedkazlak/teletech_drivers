import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/router/role_route_strategy.dart';
import 'package:teletech_drivers/core/router/role_shell_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/splash_gate.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/auth_splash_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/forced_change_password_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/login_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/register_employee_screen.dart';
const _roleRoutes = AppRoleRouteStrategy();

/// Dependency Injection: Riverpod. Redirects follow auth state and role.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Keep the session-failure listener hot before the login screen mounts.
  ref.watch(authSessionFailureProvider);

  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) {
    refresh.value++;
  });
  // Re-run redirects once the splash animation has had its moment.
  ref.listen(splashGateProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref: ref, state: state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const AuthSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterEmployeeScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        name: 'completeProfile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePasswordRequired,
        name: 'changePasswordRequired',
        builder: (context, state) => const ForcedChangePasswordScreen(),
      ),
      ...buildRoleShellRoutes(rootNavigatorKey),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect({required Ref ref, required GoRouterState state}) {
  final location = state.matchedLocation;

  // Cold start: hold the animated splash until its build-in has played.
  if (!ref.read(splashGateProvider)) return _splashUnless(location);

  final auth = ref.read(currentUserProvider);

  return auth.when(
    loading: () => _splashUnless(location),
    error: (_, _) => _splashUnless(location),
    data: (user) => _redirectForUser(user: user, location: location),
  );
}

String? _splashUnless(String location) {
  return location == AppRoutes.splash ? null : AppRoutes.splash;
}

String? _redirectForUser({required AppUser? user, required String location}) {
  final isPublic =
      location == AppRoutes.login || location == AppRoutes.register;

  if (user == null) {
    return isPublic ? null : AppRoutes.login;
  }

  if (user.mustChangePassword) {
    return location == AppRoutes.changePasswordRequired
        ? null
        : AppRoutes.changePasswordRequired;
  }

  if (user.needsProfileCompletion) {
    return location == AppRoutes.completeProfile
        ? null
        : AppRoutes.completeProfile;
  }

  if (location == AppRoutes.completeProfile) {
    return _roleRoutes.homeLocation(user.role);
  }

  final home = _roleRoutes.homeLocation(user.role);
  final onForeignRoute =
      location == AppRoutes.splash ||
      isPublic ||
      !_roleRoutes.canAccess(user.role, location);
  return onForeignRoute ? home : null;
}
