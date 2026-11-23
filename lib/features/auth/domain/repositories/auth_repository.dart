import 'dart:async';

import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';

/// Repository: authentication and the signed-in user's role.
abstract interface class AuthRepository {
  /// Observer: emits the signed-in [AppUser], or null after sign-out.
  Stream<AppUser?> authStateChanges();

  /// Observer: failures that ended a session (missing profile, denied read, …).
  Stream<Failure> watchSessionFailures();

  Future<void> signIn({required String email, required String password});

  /// Creates an employee account and signs in. Lands on the employee home.
  Future<void> registerEmployee({
    required String name,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  });

  /// Completes missing branch/phone on the signed-in employee's profile.
  Future<void> completeEmployeeProfile({
    required String uid,
    required String phone,
    required Branch branch,
  });

  Future<void> signOut();

  /// Sends only the changed profile fields. The server merges them.
  Future<void> updateProfile(ProfilePatch patch);

  /// Changes the password. The token used for this call stays valid.
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  /// Reloads the signed-in user from `GET /auth/me`.
  Future<void> refreshSession();
}
