import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/features/push/data/datasources/device_token_remote_data_source.dart';
import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';
import 'package:teletech_drivers/features/push/domain/repositories/device_token_repository.dart';

/// Repository: POST and DELETE /device-tokens.
class ApiDeviceTokenRepository implements DeviceTokenRepository {
  ApiDeviceTokenRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final DeviceTokenRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  @override
  Future<void> register({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) {
    return _guard(
      () =>
          dataSource.register(token: token, platform: platform, locale: locale),
    );
  }

  @override
  Future<void> remove(String token) {
    return _guard(() => dataSource.remove(token));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }
}
