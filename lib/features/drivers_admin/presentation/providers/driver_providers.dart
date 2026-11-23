import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/providers/driver_stats_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/list_driver_trips.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/drivers_admin/data/providers/driver_repository_provider.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/create_driver.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/fix_legacy_drivers.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/get_driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/set_driver_active.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/soft_delete_driver.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/update_driver.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/watch_all_driver_profiles.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/use_cases/watch_all_drivers.dart';

final watchAllDriversUseCaseProvider = Provider<WatchAllDriversUseCase>((ref) {
  return WatchAllDriversUseCase(ref.watch(driverRepositoryProvider));
});

final watchAllDriverProfilesUseCaseProvider =
    Provider<WatchAllDriverProfilesUseCase>((ref) {
      return WatchAllDriverProfilesUseCase(ref.watch(driverRepositoryProvider));
    });

final listDriverTripsUseCaseProvider = Provider<ListDriverTripsUseCase>((ref) {
  return ListDriverTripsUseCase(ref.watch(driverRepositoryProvider));
});

final getDriverProfileUseCaseProvider = Provider<GetDriverProfileUseCase>((
  ref,
) {
  return GetDriverProfileUseCase(ref.watch(driverRepositoryProvider));
});

final createDriverUseCaseProvider = Provider<CreateDriverUseCase>((ref) {
  return CreateDriverUseCase(ref.watch(driverRepositoryProvider));
});

final updateDriverUseCaseProvider = Provider<UpdateDriverUseCase>((ref) {
  return UpdateDriverUseCase(ref.watch(driverRepositoryProvider));
});

final setDriverActiveUseCaseProvider = Provider<SetDriverActiveUseCase>((ref) {
  return SetDriverActiveUseCase(ref.watch(driverRepositoryProvider));
});

final softDeleteDriverUseCaseProvider = Provider<SoftDeleteDriverUseCase>((
  ref,
) {
  return SoftDeleteDriverUseCase(ref.watch(driverRepositoryProvider));
});

final fixLegacyDriversUseCaseProvider = Provider<FixLegacyDriversUseCase>((
  ref,
) {
  return FixLegacyDriversUseCase(ref.watch(driverRepositoryProvider));
});

/// Observer: public driver docs (safe for company admin name lookup).
/// Dependency Injection: Riverpod.
final allDriversProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: const <AppUser>[],
    create: (_) => ref.watch(watchAllDriversUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Observer: drivers filtered by today's check-in. Null is every driver.
final driverProfilesByAttendanceProvider = StreamProvider.autoDispose
    .family<List<DriverProfile>, DriverAttendanceFilter?>((ref, attendance) {
      return authBoundStream(
        ref,
        whenSignedOut: const <DriverProfile>[],
        create: (_) => ref.watch(watchAllDriverProfilesUseCaseProvider)(
          attendance: attendance,
        ),
      );
    }, retry: (_, _) => null);

/// Completed trips for one driver, using the profile period control.
final adminDriverTripsProvider = FutureProvider.autoDispose
    .family<List<DriverCompletedTrip>, String>((ref, driverId) {
      final anchor = ref.watch(adminDriverPeriodProvider(driverId));
      return ref.watch(listDriverTripsUseCaseProvider)(
        driverId: driverId,
        period: anchor.apiPeriod,
        date: anchor.apiDate,
      );
    });

/// Observer: drivers with private licenses (Drivers Admin only).
final allDriverProfilesProvider =
    StreamProvider.autoDispose<List<DriverProfile>>((ref) {
      return authBoundStream(
        ref,
        whenSignedOut: const <DriverProfile>[],
        create: (_) => ref.watch(watchAllDriverProfilesUseCaseProvider)(),
      );
    }, retry: (_, _) => null);

/// Active drivers for the assignment picker (isActive filtered client-side).
final activeDriverProfilesProvider =
    Provider.autoDispose<AsyncValue<List<DriverProfile>>>((ref) {
      return ref
          .watch(allDriverProfilesProvider)
          .whenData(
            (drivers) => drivers.where((driver) => driver.isActive).toList(),
          );
    });

/// One driver profile for details / edit.
final driverProfileProvider = FutureProvider.autoDispose
    .family<DriverProfile, String>((ref, driverId) {
      return ref.watch(getDriverProfileUseCaseProvider)(driverId);
    });
