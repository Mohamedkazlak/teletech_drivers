import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/user_account_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/state/reset_password_state.dart';

final resetUserPasswordControllerProvider =
    NotifierProvider.autoDispose<
      ResetUserPasswordController,
      ResetPasswordState
    >(ResetUserPasswordController.new);

class ResetUserPasswordController extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() => const ResetPasswordState();

  Future<bool> submit({
    required String userId,
    required String password,
  }) async {
    if (state.isLoading) return false;
    state = const ResetPasswordState(isLoading: true);
    try {
      await ref.read(resetUserPasswordUseCaseProvider)(
        userId: userId,
        password: password,
      );
      if (!ref.mounted) return false;
      state = const ResetPasswordState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = ResetPasswordState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const ResetPasswordState(failure: UnknownFailure());
      return false;
    }
  }
}
