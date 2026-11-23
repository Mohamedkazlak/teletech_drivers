import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/network/token_storage.dart';
import 'package:teletech_drivers/core/session/session_uid_source.dart';
import 'package:teletech_drivers/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

/// Repository: Sanctum token session + `/auth/me` profile.
class ApiAuthRepository
    with WidgetsBindingObserver
    implements AuthRepository, SessionUidSource {
  ApiAuthRepository({
    required this.dataSource,
    required this.tokenStorage,
    required this.apiClient,
    this.failureMapper = const ApiFailureMapper(),
    WidgetsBinding? binding,
  }) : _binding = binding ?? WidgetsBinding.instance {
    apiClient.onSessionExpired = _onForcedSessionExpiry;
    apiClient.onPasswordChangeRequired = _onPasswordChangeRequired;
    _binding.addObserver(this);
  }

  final AuthRemoteDataSource dataSource;
  final TokenStorage tokenStorage;
  final ApiClient apiClient;
  final ApiFailureMapper failureMapper;
  final WidgetsBinding _binding;

  final _users = StreamController<AppUser?>.broadcast();
  final _sessionFailures = StreamController<Failure>.broadcast();

  AppUser? _currentUser;
  var _bootstrapped = false;
  var _disposed = false;
  var _refreshInFlight = false;

  /// In-flight calls from before the change can still return
  /// `password_change_required`. Those must not turn the flag back on.
  var _suppressPasswordChangeRequired = false;

  @override
  String? get currentUserId => _currentUser?.id;

  AppUser? get currentUser => _currentUser;

  /// Loads the stored token and hydrates the session (call once from DI).
  Future<void> bootstrap() async {
    if (_bootstrapped || _disposed) return;
    _bootstrapped = true;
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      _emitUser(null);
      return;
    }
    try {
      final dto = await dataSource.getMe();
      final user = UserDtoMapper.toEntity(dto);
      if (!user.isActive) {
        await _clearLocalSession();
        _emitSessionFailure(
          const AuthFailure(kind: AuthErrorKind.accountInactive),
        );
        _emitUser(null);
        return;
      }
      _emitUser(user);
    } on UnauthorizedApiException {
      await _clearLocalSession();
      _emitUser(null);
    } catch (error) {
      await _clearLocalSession();
      _emitSessionFailure(failureMapper.map(error));
      _emitUser(null);
    }
  }

  /// Re-validates `/auth/me` after returning from background or a mutation.
  @override
  Future<void> refreshSession() => _refreshMe(forceSignOutOn401: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshSession());
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      controller.add(_currentUser);
      final subscription = _users.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<Failure> watchSessionFailures() => _sessionFailures.stream;

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      apiClient.resetSessionExpiryLatch();
      _suppressPasswordChangeRequired = false;
      try {
        final session = await dataSource.login(
          email: email,
          password: password,
        );
        await tokenStorage.writeToken(session.token);
        final user = UserDtoMapper.toEntity(session.user);
        if (!user.isActive) {
          await _clearLocalSession();
          throw const AuthFailure(kind: AuthErrorKind.accountInactive);
        }
        _emitUser(user);
      } on UnauthorizedApiException {
        throw const AuthFailure(kind: AuthErrorKind.invalidCredentials);
      }
    });
  }

  @override
  Future<void> registerEmployee({
    required String name,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) {
    return _guard(() async {
      apiClient.resetSessionExpiryLatch();
      _suppressPasswordChangeRequired = false;
      try {
        final session = await dataSource.register(
          nameEn: name,
          nameAr: nameAr,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          phone: phone,
          branch: branch,
        );
        await tokenStorage.writeToken(session.token);
        _emitUser(UserDtoMapper.toEntity(session.user));
      } on ValidationApiException catch (error) {
        throw _mapRegisterValidation(error);
      }
    });
  }

  @override
  Future<void> completeEmployeeProfile({
    required String uid,
    required String phone,
    required Branch branch,
  }) {
    return _guard(() async {
      final dto = await dataSource.updateMe({
        ApiJsonKeys.phone: phone,
        ApiJsonKeys.branch: branch.wireValue,
      });
      final user = UserDtoMapper.toEntity(dto);
      _emitUser(user);
    });
  }

  @override
  Future<void> signOut() {
    return _guard(() async {
      try {
        await dataSource.logout();
      } on Object {
        // Local sign-out still proceeds when the network call fails.
      }
      await _clearLocalSession();
      _suppressPasswordChangeRequired = false;
      _emitUser(null);
    });
  }

  @override
  Future<void> updateProfile(ProfilePatch patch) {
    return _guard(() async {
      final changes = _profileChanges(patch);
      if (changes.isEmpty) return;
      final dto = await dataSource.updateMe(changes);
      _emitUser(UserDtoMapper.toEntity(dto));
    });
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _guard(() async {
      final UserDto dto;
      try {
        dto = await dataSource.changePassword(
          currentPassword: currentPassword,
          password: password,
          passwordConfirmation: passwordConfirmation,
        );
      } on TooManyRequestsApiException {
        throw const AuthFailure(kind: AuthErrorKind.tooManyRequests);
      }
      final user = UserDtoMapper.toEntity(dto);
      if (!user.mustChangePassword) {
        _suppressPasswordChangeRequired = true;
      }
      _emitUser(user);
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _binding.removeObserver(this);
    apiClient.onSessionExpired = null;
    apiClient.onPasswordChangeRequired = null;
    unawaited(_users.close());
    unawaited(_sessionFailures.close());
  }

  void _onPasswordChangeRequired() {
    if (_disposed || _suppressPasswordChangeRequired) return;
    final user = _currentUser;
    if (user == null || user.mustChangePassword) return;
    _emitUser(user.copyWithMustChangePassword(true));
  }

  void _onForcedSessionExpiry() {
    if (_disposed) return;
    _currentUser = null;
    _emitSessionFailure(const AuthFailure(kind: AuthErrorKind.sessionExpired));
    if (!_users.isClosed) {
      _users.add(null);
    }
  }

  Future<void> _refreshMe({required bool forceSignOutOn401}) async {
    if (_disposed || _refreshInFlight) return;
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      if (_currentUser != null) _emitUser(null);
      return;
    }
    _refreshInFlight = true;
    try {
      final dto = await dataSource.getMe();
      final user = UserDtoMapper.toEntity(dto);
      if (!user.isActive) {
        await _clearLocalSession();
        _emitSessionFailure(
          const AuthFailure(kind: AuthErrorKind.accountInactive),
        );
        _emitUser(null);
        return;
      }
      _emitUser(user);
    } on UnauthorizedApiException {
      if (!forceSignOutOn401) return;
      await _clearLocalSession();
      _emitSessionFailure(
        const AuthFailure(kind: AuthErrorKind.sessionExpired),
      );
      _emitUser(null);
    } catch (_) {
      // Keep the last known user on transient resume failures.
    } finally {
      _refreshInFlight = false;
    }
  }

  Map<String, Object?> _profileChanges(ProfilePatch patch) {
    return {
      if (patch.nameEn != null) ApiJsonKeys.nameEn: patch.nameEn,
      if (patch.nameArChanged) ApiJsonKeys.nameAr: patch.nameAr,
      if (patch.email != null) ApiJsonKeys.email: patch.email,
      if (patch.phoneChanged) ApiJsonKeys.phone: patch.phone,
      if (patch.branchChanged && patch.branch != null)
        ApiJsonKeys.branch: patch.branch!.wireValue,
    };
  }

  Failure _mapRegisterValidation(ValidationApiException error) {
    final fields = error.fieldErrors;
    if (fields.containsKey('email')) {
      return const AuthFailure(kind: AuthErrorKind.emailAlreadyInUse);
    }
    if (fields.containsKey('password')) {
      return const AuthFailure(kind: AuthErrorKind.weakPassword);
    }
    return failureMapper.map(error);
  }

  Future<void> _clearLocalSession() async {
    await tokenStorage.clearToken();
    apiClient.resetSessionExpiryLatch();
  }

  void _emitUser(AppUser? user) {
    _currentUser = user;
    if (!_users.isClosed) {
      _users.add(user);
    }
  }

  void _emitSessionFailure(Failure failure) {
    if (!_sessionFailures.isClosed) {
      _sessionFailures.add(failure);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      if (error is Failure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }
}
