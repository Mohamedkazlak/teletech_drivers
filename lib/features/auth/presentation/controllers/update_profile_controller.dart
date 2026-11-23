import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/use_cases/update_profile.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/state/profile_form_state.dart';

/// Dependency Injection: Riverpod.
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});

final updateProfileControllerProvider =
    NotifierProvider.autoDispose<UpdateProfileController, ProfileFormState>(
      UpdateProfileController.new,
    );

class UpdateProfileController extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => const ProfileFormState();

  void clearFailure() {
    if (state.failure == null && state.fieldErrors.isEmpty) return;
    state = const ProfileFormState();
  }

  Future<bool> submit({
    required String nameEn,
    required String nameAr,
    required String email,
    required String phone,
    required Branch branch,
    bool lockBranch = false,
  }) async {
    if (state.isLoading) return false;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      state = const ProfileFormState(
        failure: AuthFailure(kind: AuthErrorKind.sessionExpired),
      );
      return false;
    }

    final patch = ProfilePatch.fromForm(
      user: user,
      nameEn: nameEn,
      nameAr: nameAr,
      email: email,
      phone: phone,
      branch: branch,
      lockBranch: lockBranch,
    );
    state = const ProfileFormState(isLoading: true);
    try {
      await ref.read(updateProfileUseCaseProvider)(patch);
      if (!ref.mounted) return false;
      state = const ProfileFormState(saved: true);
      return true;
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return false;
      state = ProfileFormState(
        failure: failure,
        fieldErrors: _firstMessages(failure.fieldErrors),
      );
      return false;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = ProfileFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const ProfileFormState(failure: UnknownFailure());
      return false;
    }
  }

  Map<String, String> _firstMessages(Map<String, List<String>> errors) {
    const fields = [
      ApiJsonKeys.nameEn,
      ApiJsonKeys.nameAr,
      ApiJsonKeys.email,
      ApiJsonKeys.phone,
      ApiJsonKeys.branch,
    ];
    return {
      for (final field in fields)
        if ((errors[field]?.isNotEmpty ?? false)) field: errors[field]!.first,
    };
  }
}
