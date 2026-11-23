import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/admin/data/datasources/employee_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

class ApiEmployeeRemoteDataSource implements EmployeeRemoteDataSource {
  const ApiEmployeeRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<UserDto>> listEmployees({bool includeDeleted = false}) {
    return apiClient.fetchAllPages(
      path: ApiPaths.employees,
      query: {
        if (includeDeleted) ApiJsonKeys.includeDeleted: true,
      },
      mapItem: UserDto.fromJson,
    );
  }

  @override
  Future<UserDto> getEmployee(String employeeId) async {
    final response = await apiClient.get(ApiPaths.employee(employeeId));
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> createEmployee(Map<String, dynamic> body) async {
    final response = await apiClient.post(ApiPaths.employees, data: body);
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> body,
  }) async {
    final response = await apiClient.patch(
      ApiPaths.employee(employeeId),
      data: body,
    );
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> softDeleteEmployee(String employeeId) async {
    final response = await apiClient.delete(ApiPaths.employee(employeeId));
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> restoreEmployee(String employeeId) async {
    final response = await apiClient.post(
      ApiPaths.employeeRestore(employeeId),
    );
    return UserDto.fromJson(_asMap(response.data));
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
