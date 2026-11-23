import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

/// Employees REST API.
abstract interface class EmployeeRemoteDataSource {
  Future<List<UserDto>> listEmployees({bool includeDeleted = false});

  Future<UserDto> getEmployee(String employeeId);

  Future<UserDto> createEmployee(Map<String, dynamic> body);

  Future<UserDto> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> body,
  });

  Future<UserDto> softDeleteEmployee(String employeeId);

  Future<UserDto> restoreEmployee(String employeeId);
}
