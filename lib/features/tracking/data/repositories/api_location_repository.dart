import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/location_remote_data_source.dart';
import 'package:teletech_drivers/features/tracking/data/mappers/live_map_item_dto_mapper.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';

/// Repository: Laravel driver-location and live-map API.
class ApiLocationRepository implements LocationRepository {
  ApiLocationRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final LocationRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _polling = <PollingStream<List<LiveMapDriver>>>[];

  @override
  Future<DriverLocationPublishOutcome> publishLocation({
    required Position position,
    String? tripId,
  }) async {
    try {
      await dataSource.publish(position: position, tripId: tripId);
      return DriverLocationPublishOutcome.published;
    } on ValidationApiException {
      return DriverLocationPublishOutcome.skipped;
    } on TooManyRequestsApiException {
      return DriverLocationPublishOutcome.backedOff;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }

  @override
  Future<void> stopTracking() async {
    try {
      await dataSource.stop();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }

  @override
  Stream<List<LiveMapDriver>> watchLiveMap({String? driverId}) {
    final polling = PollingStream<List<LiveMapDriver>>(
      fetch: () async {
        final items = await dataSource.listLiveMap(driverId: driverId);
        return [for (final item in items) LiveMapItemDtoMapper.toEntity(item)];
      },
      interval: PollingIntervals.liveMap,
    );
    _polling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    });
  }

  void dispose() {
    for (final stream in _polling) {
      stream.dispose();
    }
    _polling.clear();
  }
}
