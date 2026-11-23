import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/tracking/data/models/live_map_item_dto.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_state.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';

/// Maps live-map JSON onto domain rows. [LiveMapDriver.isStale] is copied
/// from the server and is not recomputed.
abstract final class LiveMapItemDtoMapper {
  static LiveMapDriver toEntity(LiveMapItemDto dto) {
    final trip = dto.trip;
    final parsedState = LiveMapState.fromApi(dto.state);
    return LiveMapDriver(
      driver: UserDtoMapper.toEntity(dto.driver),
      state: parsedState ??
          (trip == null ? LiveMapState.unavailable : LiveMapState.onTrip),
      trip: trip == null
          ? null
          : LiveMapTripSummary(
              id: trip.id,
              status: TripStatusMapper.fromApi(trip.status),
              pickupSummary: trip.pickupSummary,
              destinationSummary: trip.destinationSummary,
              scheduledAt: trip.scheduledAt,
              goingStartedAt: trip.goingStartedAt,
            ),
      lat: dto.lat,
      lng: dto.lng,
      heading: dto.heading,
      speed: dto.speed,
      accuracy: dto.accuracy,
      updatedAt: dto.updatedAt,
      lastSeenAt: dto.lastSeenAt ?? dto.updatedAt,
      isStale: dto.isStale,
      isTracking: dto.isTracking,
    );
  }
}
