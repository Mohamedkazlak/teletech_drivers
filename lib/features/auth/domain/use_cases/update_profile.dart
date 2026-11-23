import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

/// Saves changed profile fields via `PATCH /auth/me`.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(ProfilePatch patch) {
    if (patch.isEmpty) return Future<void>.value();
    return _repository.updateProfile(patch);
  }
}
