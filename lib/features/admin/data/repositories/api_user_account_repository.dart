import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/admin/data/datasources/user_account_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/domain/repositories/user_account_repository.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

/// Repository: Laravel users API for system-admin password resets.
class ApiUserAccountRepository implements UserAccountRepository {
  ApiUserAccountRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final UserAccountRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _polling = <PollingStream<List<AppUser>>>[];

  @override
  Stream<List<AppUser>> watchAllUsers() {
    final polling = PollingStream<List<AppUser>>(
      fetch: _loadUsers,
      interval: PollingIntervals.users,
    );
    _polling.add(polling);
    return polling.stream.handleError(_rethrowMapped);
  }

  @override
  Future<void> resetPassword({
    required String userId,
    required String password,
  }) {
    return _guard(() async {
      await dataSource.resetPassword(userId: userId, password: password);
    });
  }

  void dispose() {
    for (final stream in _polling) {
      stream.dispose();
    }
    _polling.clear();
  }

  Future<List<AppUser>> _loadUsers() async {
    final dtos = await dataSource.listUsers();
    final users = [for (final dto in dtos) UserDtoMapper.toEntity(dto)]
      ..sort(
        (a, b) => a.localizedName('en').toLowerCase().compareTo(
          b.localizedName('en').toLowerCase(),
        ),
      );
    return users;
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
}
