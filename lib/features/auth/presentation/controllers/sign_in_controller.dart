import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/state/auth_form_state.dart';

/// Dependency Injection: Riverpod.
final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, AuthFormState>(
      SignInController.new,
    );

class SignInController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const AuthFormState();
  }

  Future<void> submit({required String email, required String password}) {
    return _submit(
      () => ref.read(signInUseCaseProvider)(email: email, password: password),
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AuthFormState(isLoading: true);
    try {
      await action();
      if (!ref.mounted) return;
      state = const AuthFormState();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = AuthFormState(failure: failure);
    } on Object {
      if (!ref.mounted) return;
      state = const AuthFormState(failure: UnknownFailure());
    }
  }
}
