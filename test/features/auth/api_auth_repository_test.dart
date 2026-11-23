import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/models/auth_token_dto.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/data/repositories/api_auth_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

import '../../core/network/fake_token_storage.dart';

class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote({this.me});

  UserDto? me;
  var getMeCalls = 0;
  var logoutCalls = 0;
  Object? loginError;

  @override
  Future<UserDto> getMe() async {
    getMeCalls++;
    if (me == null) throw const UnauthorizedApiException();
    return me!;
  }

  @override
  Future<AuthTokenDto> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return AuthTokenDto(token: 'tok', tokenType: 'Bearer', user: me!);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }

  Object? logoutError;

  @override
  Future<UserDto> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final current = me ?? _employee();
    me = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      email: current.email,
      role: current.role,
      isActive: current.isActive,
      phone: current.phone,
      branch: current.branch,
    );
    return me!;
  }

  @override
  Future<AuthTokenDto> register({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> updateMe(Map<String, Object?> changes) async {
    me = UserDto(
      id: me!.id,
      email: (changes['email'] as String?) ?? me!.email,
      role: me!.role,
      isActive: me!.isActive,
      nameEn: (changes['name_en'] as String?) ?? me!.nameEn,
      nameAr: changes.containsKey('name_ar')
          ? changes['name_ar'] as String?
          : me!.nameAr,
      phone: changes.containsKey('phone')
          ? changes['phone'] as String?
          : me!.phone,
      branch: changes.containsKey('branch')
          ? Branch.fromWire(changes['branch'] as String?)
          : me!.branch,
    );
    return me!;
  }
}

UserDto _employee({bool active = true}) {
  return UserDto(
    id: 'u1',
    nameEn: 'Ada',
    email: 'ada@test.com',
    role: UserRole.employee,
    isActive: active,
    phone: '0100',
    branch: Branch.companyHeadquarters,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTokenStorage storage;
  late _FakeAuthRemote remote;
  late ApiClient apiClient;
  late ApiAuthRepository repository;

  setUp(() {
    storage = FakeTokenStorage();
    remote = _FakeAuthRemote(me: _employee());
    apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://example.test/api',
    );
    repository = ApiAuthRepository(
      dataSource: remote,
      tokenStorage: storage,
      apiClient: apiClient,
      binding: WidgetsBinding.instance,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  test('bootstrap with valid token signs in', () async {
    storage.token = 'tok';
    await repository.bootstrap();
    expect(repository.currentUser?.email, 'ada@test.com');
    expect(remote.getMeCalls, 1);
  });

  test('bootstrap with invalid token signs out', () async {
    storage.token = 'bad';
    remote.me = null;
    await repository.bootstrap();
    expect(repository.currentUser, isNull);
    expect(storage.token, isNull);
  });

  test('logout clears token and user', () async {
    storage.token = 'tok';
    await repository.bootstrap();
    await repository.signOut();
    expect(remote.logoutCalls, 1);
    expect(storage.token, isNull);
    expect(repository.currentUser, isNull);
  });

  test('logout still clears the session when the API call fails', () async {
    storage.token = 'tok';
    await repository.bootstrap();
    remote.logoutError = const NetworkApiException();
    await repository.signOut();
    expect(storage.token, isNull);
    expect(repository.currentUser, isNull);
  });

  test('forced session expiry emits failure once', () async {
    storage.token = 'tok';
    await repository.bootstrap();
    final failures = <Failure>[];
    final sub = repository.watchSessionFailures().listen(failures.add);

    apiClient.onSessionExpired?.call();
    await Future<void>.delayed(Duration.zero);

    expect(failures, [const AuthFailure(kind: AuthErrorKind.sessionExpired)]);
    expect(repository.currentUser, isNull);
    await sub.cancel();
  });

  test(
    'change password publishes the returned user and skips /auth/me',
    () async {
      storage.token = 'tok';
      remote.me = UserDto(
        id: 'u1',
        nameEn: 'Ada',
        email: 'ada@test.com',
        role: UserRole.employee,
        isActive: true,
        phone: '0100',
        branch: Branch.companyHeadquarters,
        mustChangePassword: true,
      );
      await repository.bootstrap();
      remote.getMeCalls = 0;

      await repository.changePassword(
        currentPassword: 'temporary1',
        password: 'newpassword1',
        passwordConfirmation: 'newpassword1',
      );

      expect(remote.getMeCalls, 0);
      expect(repository.currentUser?.mustChangePassword, isFalse);

      apiClient.onPasswordChangeRequired?.call();
      expect(repository.currentUser?.mustChangePassword, isFalse);
    },
  );

  test('resume refresh signs out on 401', () async {
    storage.token = 'tok';
    await repository.bootstrap();
    remote.me = null;
    await repository.refreshSession();
    expect(repository.currentUser, isNull);
    expect(storage.token, isNull);
  });
}
