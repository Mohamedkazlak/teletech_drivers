import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Fields that differ from the signed-in user. Absent fields are not sent.
///
/// `name_ar` uses [nameArChanged] so a cleared name is sent as null
/// instead of being omitted.
final class ProfilePatch extends Equatable {
  const ProfilePatch({
    this.nameEn,
    this.nameAr,
    this.email,
    this.phone,
    this.branch,
    this.nameArChanged = false,
    this.phoneChanged = false,
    this.branchChanged = false,
  });

  final String? nameEn;
  final String? nameAr;
  final String? email;
  final String? phone;
  final Branch? branch;
  final bool nameArChanged;
  final bool phoneChanged;
  final bool branchChanged;

  bool get isEmpty =>
      nameEn == null &&
      email == null &&
      !nameArChanged &&
      !phoneChanged &&
      !branchChanged;

  /// Compares the form with [user] and keeps only the values that changed.
  factory ProfilePatch.fromForm({
    required AppUser user,
    required String nameEn,
    required String nameAr,
    required String email,
    required String phone,
    required Branch branch,
    bool lockBranch = false,
  }) {
    final nextName = nameEn.trim();
    final previousName = (user.nameEn ?? user.name).trim();
    final nextEmail = email.trim();
    final nextPhone = phone.trim();
    final nextAr = nameAr.trim();
    final previousAr = user.nameAr?.trim() ?? '';
    final nameArChanged = nextAr != previousAr;
    final phoneChanged = nextPhone != (user.phone?.trim() ?? '');
    final branchChanged = !lockBranch && branch != user.branch;

    return ProfilePatch(
      nameEn: nextName == previousName ? null : nextName,
      nameAr: nameArChanged && nextAr.isNotEmpty ? nextAr : null,
      email: nextEmail == user.email.trim() ? null : nextEmail,
      phone: phoneChanged ? nextPhone : null,
      branch: branchChanged ? branch : null,
      nameArChanged: nameArChanged,
      phoneChanged: phoneChanged,
      branchChanged: branchChanged,
    );
  }

  @override
  List<Object?> get props => [
    nameEn,
    nameAr,
    email,
    phone,
    branch,
    nameArChanged,
    phoneChanged,
    branchChanged,
  ];
}
