import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/change_password.dart';
import 'package:teletech_drivers/features/auth/presentation/state/change_password_state.dart';

/// Dependency Injection: Riverpod.
final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );

class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  void clearFailure() {
    if (state.failure == null && state.fieldErrors.isEmpty) return;
    state = const ChangePasswordState();
  }

  void clearSaved() {
    if (!state.saved) return;
    state = const ChangePasswordState();
  }

  Future<bool> submit({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state.isLoading) return false;
    state = const ChangePasswordState(isLoading: true);
    try {
      await ref.read(changePasswordUseCaseProvider)(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      if (!ref.mounted) return false;
      state = const ChangePasswordState(saved: true);
      return true;
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return false;
      state = ChangePasswordState(
        failure: failure,
        fieldErrors: _firstMessages(failure.fieldErrors),
      );
      return false;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = ChangePasswordState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const ChangePasswordState(failure: UnknownFailure());
      return false;
    }
  }

  Map<String, String> _firstMessages(Map<String, List<String>> errors) {
    const fields = [
      ApiJsonKeys.currentPassword,
      ApiJsonKeys.password,
      ApiJsonKeys.passwordConfirmation,
    ];
    return {
      for (final field in fields)
        if ((errors[field]?.isNotEmpty ?? false)) field: errors[field]!.first,
    };
  }
}
