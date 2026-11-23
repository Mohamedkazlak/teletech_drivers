import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/complete_employee_profile.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/register_employee.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/sign_in.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/sign_out.dart';

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final registerEmployeeUseCaseProvider = Provider<RegisterEmployeeUseCase>((
  ref,
) {
  return RegisterEmployeeUseCase(ref.watch(authRepositoryProvider));
});

final completeEmployeeProfileUseCaseProvider =
    Provider<CompleteEmployeeProfileUseCase>((ref) {
      return CompleteEmployeeProfileUseCase(ref.watch(authRepositoryProvider));
    });

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

/// True while sign-out is cancelling session streams (before the token clears).
/// Dependency Injection: Riverpod. State: session lifecycle.
final sessionSigningOutProvider =
    NotifierProvider<SessionSigningOutNotifier, bool>(
      SessionSigningOutNotifier.new,
    );

class SessionSigningOutNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Stops auth-bound streams, then runs [signOut].
  Future<void> run(Future<void> Function() signOut) async {
    state = true;
    // Yield so StreamProviders rebuild and cancel listens while still authed.
    await Future<void>.delayed(Duration.zero);
    try {
      await signOut();
    } finally {
      state = false;
    }
  }
}

/// Session failures that forced sign-out (missing profile, permission, …).
/// Shown once on the login screen until cleared.
final authSessionFailureProvider =
    NotifierProvider<AuthSessionFailureNotifier, Failure?>(
      AuthSessionFailureNotifier.new,
    );

class AuthSessionFailureNotifier extends Notifier<Failure?> {
  @override
  Failure? build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .watchSessionFailures()
        .listen((failure) {
          state = failure;
        });
    ref.onDispose(subscription.cancel);
    return null;
  }

  void clear() {
    if (state == null) return;
    state = null;
  }
}

/// Observer: the signed-in user, or null after sign-out.
/// Dependency Injection: Riverpod.
final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (_, _) => null,
);
