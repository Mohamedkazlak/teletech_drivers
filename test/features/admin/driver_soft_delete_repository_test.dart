import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/drivers_admin/data/datasources/driver_remote_data_source.dart';
import 'package:teletech_drivers/features/drivers_admin/data/models/driver_completed_trip_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/data/repositories/api_driver_repository.dart';

class _FakeDriverRemote implements DriverRemoteDataSource {
  final Map<String, UserDto> users = {};
  var softDeleteCalls = 0;
  var restoreCalls = 0;

  @override
  Future<UserDto> createDriver(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> getDriver(String driverId) async => users[driverId]!;

  @override
  Future<List<UserDto>> listDrivers({
    bool includeDeleted = false,
    String? attendance,
  }) async {
    return users.values.toList();
  }

  @override
  Future<List<DriverCompletedTripDto>> listDriverTrips(
    String driverId, {
    String? period,
    String? date,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> restoreDriver(String driverId) async {
    restoreCalls++;
    final current = users[driverId]!;
    final restored = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      nameAr: current.nameAr,
      email: current.email,
      role: current.role,
      isActive: true,
      phone: current.phone,
      favoritePlaceIds: current.favoritePlaceIds,
    );
    users[driverId] = restored;
    return restored;
  }

  @override
  Future<UserDto> softDeleteDriver(String driverId) async {
    softDeleteCalls++;
    final current = users[driverId]!;
    final deleted = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      nameAr: current.nameAr,
      email: current.email,
      role: current.role,
      isActive: false,
      phone: current.phone,
      favoritePlaceIds: current.favoritePlaceIds,
      deletedAt: DateTime.utc(2026, 1, 1),
      deletedBy: 'admin',
    );
    users[driverId] = deleted;
    return deleted;
  }

  @override
  Future<UserDto> updateDriver({
    required String driverId,
    required Map<String, dynamic> body,
  }) async {
    final current = users[driverId]!;
    final updated = UserDto(
      id: current.id,
      nameEn: current.nameEn,
      nameAr: current.nameAr,
      email: current.email,
      role: current.role,
      isActive: (body['is_active'] as bool?) ?? current.isActive,
      phone: current.phone,
      favoritePlaceIds: current.favoritePlaceIds,
      deletedAt: current.deletedAt,
      deletedBy: current.deletedBy,
    );
    users[driverId] = updated;
    return updated;
  }
}

void main() {
  test('softDeleteDriver uses DELETE and restore uses POST restore', () async {
    final remote = _FakeDriverRemote();
    remote.users['d1'] = UserDto(
      id: 'd1',
      nameEn: 'Driver',
      nameAr: 'سائق',
      email: 'd@test.com',
      role: UserRole.driver,
      isActive: true,
      phone: '0100',
    );
    final repository = ApiDriverRepository(
      dataSource: remote,
      includeDeleted: () => true,
    );

    await repository.softDeleteDriver(driverId: 'd1', deletedBy: 'admin');
    expect(remote.softDeleteCalls, 1);
    expect(remote.users['d1']?.deletedAt, isNotNull);

    await repository.setDriverActive(driverId: 'd1', isActive: true);
    expect(remote.restoreCalls, 1);
    expect(remote.users['d1']?.isActive, isTrue);

    repository.dispose();
  });
}
