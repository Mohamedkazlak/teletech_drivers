import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/state/auth_form_state.dart';

/// Dependency Injection: Riverpod.
final registerEmployeeControllerProvider =
    NotifierProvider.autoDispose<RegisterEmployeeController, AuthFormState>(
      RegisterEmployeeController.new,
    );

class RegisterEmployeeController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const AuthFormState();
  }

  Future<void> submit({
    required String name,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) async {
    if (state.isLoading) return;
    state = const AuthFormState(isLoading: true);
    try {
      await ref.read(registerEmployeeUseCaseProvider)(
        name: name,
        nameAr: nameAr,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        branch: branch,
      );
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
