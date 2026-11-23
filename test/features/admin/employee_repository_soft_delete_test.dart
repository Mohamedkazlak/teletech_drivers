import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/admin/data/datasources/employee_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/data/repositories/api_employee_repository.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

class _FakeEmployeeRemote implements EmployeeRemoteDataSource {
  final Map<String, UserDto> users = {};
  Map<String, dynamic>? lastCreateBody;
  var softDeleteCalls = 0;
  var restoreCalls = 0;

  @override
  Future<UserDto> createEmployee(Map<String, dynamic> body) async {
    lastCreateBody = body;
    final dto = UserDto(
      id: 'new-emp',
      nameEn: body['name_en'] as String,
      nameAr: body['name_ar'] as String?,
      email: body['email'] as String,
      role: UserRole.employee,
      isActive: true,
      phone: body['phone'] as String?,
      branch: Branch.fromWire(body['branch'] as String),
    );
    users[dto.id] = dto;
    return dto;
  }

  @override
  Future<UserDto> getEmployee(String employeeId) async => users[employeeId]!;

  @override
  Future<List<UserDto>> listEmployees({bool includeDeleted = false}) async {
    return users.values.toList();
  }

  @override
  Future<UserDto> restoreEmployee(String employeeId) async {
    restoreCalls++;
    final current = users[employeeId]!;
    final restored = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      nameAr: current.nameAr,
      email: current.email,
      role: current.role,
      isActive: true,
      phone: current.phone,
      branch: current.branch,
    );
    users[employeeId] = restored;
    return restored;
  }

  @override
  Future<UserDto> softDeleteEmployee(String employeeId) async {
    softDeleteCalls++;
    final current = users[employeeId]!;
    final deleted = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      nameAr: current.nameAr,
      email: current.email,
      role: current.role,
      isActive: false,
      phone: current.phone,
      branch: current.branch,
      deletedAt: DateTime.utc(2026, 1, 1),
      deletedBy: 'admin',
    );
    users[employeeId] = deleted;
    return deleted;
  }

  @override
  Future<UserDto> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> body,
  }) async {
    final current = users[employeeId]!;
    final updated = UserDto(
      id: current.id,
      nameEn: (body['name_en'] as String?) ?? current.nameEn,
      nameAr: (body['name_ar'] as String?) ?? current.nameAr,
      email: current.email,
      role: current.role,
      isActive: (body['is_active'] as bool?) ?? current.isActive,
      phone: (body['phone'] as String?) ?? current.phone,
      branch: body['branch'] is String
          ? Branch.fromWire(body['branch'] as String)
          : current.branch,
      deletedAt: current.deletedAt,
      deletedBy: current.deletedBy,
    );
    users[employeeId] = updated;
    return updated;
  }
}

void main() {
  group('ApiEmployeeRepository', () {
    late _FakeEmployeeRemote remote;
    late ApiEmployeeRepository repository;

    setUp(() {
      remote = _FakeEmployeeRemote();
      repository = ApiEmployeeRepository(
        dataSource: remote,
        includeDeleted: () => true,
      );
    });

    tearDown(() => repository.dispose());

    test('createEmployee posts a single payload (no secondary auth)', () async {
      await repository.createEmployee(
        nameEn: 'Ada',
        nameAr: 'آدا',
        email: 'ada@test.com',
        password: 'password1',
        phone: '01000000000',
        branch: Branch.companyHeadquarters,
      );

      expect(remote.lastCreateBody?['email'], 'ada@test.com');
      expect(remote.users['new-emp']?.role, UserRole.employee);
    });

    test('softDeleteEmployee calls DELETE endpoint', () async {
      remote.users['e1'] = UserDto(
        id: 'e1',
        nameEn: 'Ada',
        email: 'ada@test.com',
        role: UserRole.employee,
        isActive: true,
        branch: Branch.newHeadquarters,
      );

      await repository.softDeleteEmployee(
        employeeId: 'e1',
        deletedBy: 'admin',
      );

      expect(remote.softDeleteCalls, 1);
      expect(remote.users['e1']?.isActive, isFalse);
      expect(remote.users['e1']?.deletedAt, isNotNull);
    });

    test('setEmployeeActive true restores soft-deleted employees', () async {
      remote.users['e1'] = UserDto(
        id: 'e1',
        nameEn: 'Ada',
        email: 'ada@test.com',
        role: UserRole.employee,
        isActive: false,
        branch: Branch.newHeadquarters,
        deletedAt: DateTime.utc(2026, 1, 1),
        deletedBy: 'admin',
      );

      await repository.setEmployeeActive(employeeId: 'e1', isActive: true);
      expect(remote.restoreCalls, 1);
      expect(remote.users['e1']?.isActive, isTrue);
    });
  });
}
