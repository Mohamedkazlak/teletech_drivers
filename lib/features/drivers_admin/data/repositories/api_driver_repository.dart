import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/drivers_admin/data/datasources/driver_remote_data_source.dart';
import 'package:teletech_drivers/features/drivers_admin/data/mappers/driver_dto_mapper.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

/// Repository: Laravel drivers API.
class ApiDriverRepository implements DriverRepository {
  ApiDriverRepository({
    required this.dataSource,
    required this.includeDeleted,
    this.failureMapper = const ApiFailureMapper(),
  });

  final DriverRemoteDataSource dataSource;

  /// `include_deleted` is admin-only on the backend.
  final bool Function() includeDeleted;
  final ApiFailureMapper failureMapper;

  final _disposers = <void Function()>[];

  @override
  Stream<List<AppUser>> watchAllDrivers() {
    final polling = PollingStream<List<AppUser>>(
      fetch: _loadDrivers,
      interval: PollingIntervals.drivers,
    );
    _disposers.add(polling.dispose);
    return polling.stream.handleError(_rethrowMapped);
  }

  @override
  Stream<List<DriverProfile>> watchAllDriverProfiles() {
    return watchDriverProfiles();
  }

  @override
  Stream<List<DriverProfile>> watchDriverProfiles({
    DriverAttendanceFilter? attendance,
  }) {
    final polling = PollingStream<List<DriverProfile>>(
      fetch: () => _loadProfiles(attendance: attendance),
      interval: PollingIntervals.drivers,
    );
    _disposers.add(polling.dispose);
    return polling.stream.handleError(_rethrowMapped);
  }

  @override
  Future<List<DriverCompletedTrip>> listDriverTrips({
    required String driverId,
    String? period,
    String? date,
  }) {
    return _guardValue(() async {
      final dtos = await dataSource.listDriverTrips(
        driverId,
        period: period,
        date: date,
      );
      return [for (final dto in dtos) DriverDtoMapper.toCompletedTrip(dto)];
    });
  }

  @override
  Future<DriverProfile> getDriverProfile(String driverId) {
    return _guardValue(() async {
      final dto = await dataSource.getDriver(driverId);
      if (dto.role != UserRole.driver) throw const InvalidStateFailure();
      return DriverDtoMapper.toProfile(dto);
    });
  }

  @override
  Future<void> createDriver({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  }) {
    return _guard(() async {
      await dataSource.createDriver({
        ApiJsonKeys.nameEn: nameEn,
        ApiJsonKeys.nameAr: nameAr,
        ApiJsonKeys.email: email,
        ApiJsonKeys.password: password,
        ApiJsonKeys.phone: phone,
        ApiJsonKeys.nationalId: nationalId,
        ApiJsonKeys.carLicense: carLicense,
        ApiJsonKeys.personalLicense: personalLicense,
        ApiJsonKeys.favoritePlaceIds: favoritePlaceIds,
      });
    });
  }

  @override
  Future<void> setDriverActive({
    required String driverId,
    required bool isActive,
  }) {
    return _guard(() async {
      final dto = await dataSource.getDriver(driverId);
      if (dto.role != UserRole.driver) throw const InvalidStateFailure();

      if (isActive) {
        if (dto.deletedAt != null) {
          await dataSource.restoreDriver(driverId);
          return;
        }
        await dataSource.updateDriver(
          driverId: driverId,
          body: {ApiJsonKeys.isActive: true},
        );
        return;
      }

      await dataSource.updateDriver(
        driverId: driverId,
        body: {ApiJsonKeys.isActive: false},
      );
    });
  }

  @override
  Future<void> softDeleteDriver({
    required String driverId,
    required String deletedBy,
  }) {
    return _guard(() async {
      final dto = await dataSource.getDriver(driverId);
      if (dto.role != UserRole.driver) throw const InvalidStateFailure();
      await dataSource.softDeleteDriver(driverId);
    });
  }

  @override
  Future<void> updateDriver({
    required String driverId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  }) {
    return _guard(() async {
      final dto = await dataSource.getDriver(driverId);
      if (dto.role != UserRole.driver) throw const InvalidStateFailure();
      await dataSource.updateDriver(
        driverId: driverId,
        body: {
          ApiJsonKeys.nameEn: nameEn,
          ApiJsonKeys.nameAr: nameAr,
          ApiJsonKeys.phone: phone,
          ApiJsonKeys.nationalId: nationalId,
          ApiJsonKeys.carLicense: carLicense,
          ApiJsonKeys.personalLicense: personalLicense,
          ApiJsonKeys.favoritePlaceIds: favoritePlaceIds,
        },
      );
    });
  }

  @override
  Future<int> fixLegacyDriverDocuments() async {
    // Laravel stores normalized profiles; no client-side legacy repair.
    return 0;
  }

  void dispose() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  }

  Future<List<AppUser>> _loadDrivers() async {
    final dtos = await _listWithDeletedFallback();
    final drivers =
        [
          for (final dto in dtos)
            if (dto.role == UserRole.driver) DriverDtoMapper.toAppUser(dto),
        ]..sort(
          (a, b) => a
              .localizedName('en')
              .toLowerCase()
              .compareTo(b.localizedName('en').toLowerCase()),
        );
    return drivers;
  }

  Future<List<DriverProfile>> _loadProfiles({
    DriverAttendanceFilter? attendance,
  }) async {
    final dtos = attendance == null
        ? await _listWithDeletedFallback()
        : await dataSource.listDrivers(attendance: attendance.apiValue);
    final profiles = [
      for (final dto in dtos)
        if (dto.role == UserRole.driver) DriverDtoMapper.toProfile(dto),
    ]..sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
    return profiles;
  }

  Future<List<UserDto>> _listWithDeletedFallback() async {
    final wantDeleted = includeDeleted();
    if (!wantDeleted) {
      return dataSource.listDrivers();
    }
    try {
      return await dataSource.listDrivers(includeDeleted: true);
    } on ForbiddenApiException {
      return dataSource.listDrivers();
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
