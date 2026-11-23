import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/state/auth_form_state.dart';

/// Dependency Injection: Riverpod.
final completeProfileControllerProvider =
    NotifierProvider.autoDispose<CompleteProfileController, AuthFormState>(
      CompleteProfileController.new,
    );

class CompleteProfileController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const AuthFormState();
  }

  Future<bool> submit({
    required String phone,
    required Branch branch,
  }) async {
    if (state.isLoading) return false;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      state = const AuthFormState(failure: UnknownFailure());
      return false;
    }

    state = const AuthFormState(isLoading: true);
    try {
      await ref.read(completeEmployeeProfileUseCaseProvider)(
        uid: user.id,
        phone: phone,
        branch: branch,
      );
      if (!ref.mounted) return false;
      state = const AuthFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = AuthFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const AuthFormState(failure: UnknownFailure());
      return false;
    }
  }
}
