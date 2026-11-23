import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/admin/data/datasources/employee_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';

/// Repository: Laravel employees API.
class ApiEmployeeRepository implements EmployeeRepository {
  ApiEmployeeRepository({
    required this.dataSource,
    required this.includeDeleted,
    this.failureMapper = const ApiFailureMapper(),
  });

  final EmployeeRemoteDataSource dataSource;
  final bool Function() includeDeleted;
  final ApiFailureMapper failureMapper;

  final _polling = <PollingStream<List<AppUser>>>[];

  @override
  Stream<List<AppUser>> watchAllEmployees() {
    final polling = PollingStream<List<AppUser>>(
      fetch: _loadEmployees,
      interval: PollingIntervals.employees,
    );
    _polling.add(polling);
    return polling.stream.handleError(_rethrowMapped);
  }

  @override
  Future<AppUser> getEmployee(String employeeId) {
    return _guardValue(() async {
      final dto = await dataSource.getEmployee(employeeId);
      if (dto.role != UserRole.employee) throw const InvalidStateFailure();
      return UserDtoMapper.toEntity(dto);
    });
  }

  @override
  Future<void> createEmployee({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required Branch branch,
  }) {
    return _guard(() async {
      await dataSource.createEmployee({
        ApiJsonKeys.nameEn: nameEn,
        ApiJsonKeys.nameAr: nameAr,
        ApiJsonKeys.email: email,
        ApiJsonKeys.password: password,
        ApiJsonKeys.phone: phone,
        ApiJsonKeys.branch: branch.wireValue,
      });
    });
  }

  @override
  Future<void> updateEmployee({
    required String employeeId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required Branch branch,
  }) {
    return _guard(() async {
      final dto = await dataSource.getEmployee(employeeId);
      if (dto.role != UserRole.employee) throw const InvalidStateFailure();
      await dataSource.updateEmployee(
        employeeId: employeeId,
        body: {
          ApiJsonKeys.nameEn: nameEn,
          ApiJsonKeys.nameAr: nameAr,
          ApiJsonKeys.phone: phone,
          ApiJsonKeys.branch: branch.wireValue,
        },
      );
    });
  }

  @override
  Future<void> softDeleteEmployee({
    required String employeeId,
    required String deletedBy,
  }) {
    return _guard(() async {
      final dto = await dataSource.getEmployee(employeeId);
      if (dto.role != UserRole.employee) throw const InvalidStateFailure();
      await dataSource.softDeleteEmployee(employeeId);
    });
  }

  @override
  Future<void> setEmployeeActive({
    required String employeeId,
    required bool isActive,
  }) {
    return _guard(() async {
      final dto = await dataSource.getEmployee(employeeId);
      if (dto.role != UserRole.employee) throw const InvalidStateFailure();

      if (isActive) {
        if (dto.deletedAt != null) {
          await dataSource.restoreEmployee(employeeId);
          return;
        }
        await dataSource.updateEmployee(
          employeeId: employeeId,
          body: {ApiJsonKeys.isActive: true},
        );
        return;
      }

      await dataSource.updateEmployee(
        employeeId: employeeId,
        body: {ApiJsonKeys.isActive: false},
      );
    });
  }

  void dispose() {
    for (final stream in _polling) {
      stream.dispose();
    }
    _polling.clear();
  }

  Future<List<AppUser>> _loadEmployees() async {
    final dtos = await _listWithDeletedFallback();
    final employees = [
      for (final dto in dtos)
        if (dto.role == UserRole.employee) UserDtoMapper.toEntity(dto),
    ]..sort(
      (a, b) => a
          .localizedName('en')
          .toLowerCase()
          .compareTo(b.localizedName('en').toLowerCase()),
    );
    return employees;
  }

  Future<List<UserDto>> _listWithDeletedFallback() async {
    final wantDeleted = includeDeleted();
    if (!wantDeleted) {
      return dataSource.listEmployees();
    }
    try {
      return await dataSource.listEmployees(includeDeleted: true);
    } on ForbiddenApiException {
      return dataSource.listEmployees();
    }
  }

  void _rethrowMapped(Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
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

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      if (error is Failure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }
}
