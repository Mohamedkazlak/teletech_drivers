import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_dto_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/driver_recommendation_dto.dart';

import '../../support/api_fixtures.dart';

DriverRecommendation _map(Map<String, dynamic> json) {
  return TripDtoMapper.toRecommendation(DriverRecommendationDto.fromJson(json));
}

void main() {
  group('DriverRecommendationDto.fromJson', () {
    test('parses tier, flags and nested driver', () {
      final dto = DriverRecommendationDto.fromJson(
        ApiFixtures.driverRecommendation(
          tier: 2,
          hasConflict: true,
          needsConfirmation: true,
          tripsThisWeek: 5,
        ),
      );

      expect(dto.driver.id, 'drv-1');
      expect(dto.tier, 2);
      expect(dto.hasFavoriteMatch, isTrue);
      expect(dto.hasConflict, isTrue);
      expect(dto.isUnavailable, isFalse);
      expect(dto.needsConfirmation, isTrue);
      expect(dto.tripsThisWeek, 5);
    });

    test('missing trips_this_week defaults to zero and flags to false', () {
      final dto = DriverRecommendationDto.fromJson({
        'driver': ApiFixtures.user(),
        'tier': 0,
      });

      expect(dto.tripsThisWeek, 0);
      expect(dto.hasFavoriteMatch, isFalse);
      expect(dto.hasConflict, isFalse);
      expect(dto.isUnavailable, isFalse);
      expect(dto.needsConfirmation, isFalse);
      expect(dto.isOnActiveTrip, isFalse);
    });

    test('requires driver and tier', () {
      expect(
        () => DriverRecommendationDto.fromJson({'tier': 1}),
        throwsFormatException,
      );
      expect(
        () => DriverRecommendationDto.fromJson({'driver': ApiFixtures.user()}),
        throwsFormatException,
      );
    });
  });

  group('TripDtoMapper.toRecommendation', () {
    test('maps the driver profile', () {
      final recommendation = _map(ApiFixtures.driverRecommendation());

      expect(recommendation.driver.id, 'drv-1');
      expect(recommendation.driver.nameEn, 'Omar Driver');
      expect(recommendation.driver.nameAr, 'عمر');
      expect(recommendation.driver.email, 'omar@example.test');
      expect(recommendation.driver.isAvailable, isTrue);
      expect(recommendation.driver.favoritePlaceIds, ['place-airport']);
      expect(recommendation.tripsThisWeek, 3);
    });

    test('tier 1 available driver without conflict is recommended', () {
      final recommendation = _map(ApiFixtures.driverRecommendation(tier: 1));

      expect(recommendation.isRecommended, isTrue);
      expect(recommendation.isAvailable, isTrue);
      expect(recommendation.hasScheduleConflict, isFalse);
      expect(recommendation.isOnActiveTrip, isFalse);
      expect(recommendation.favoriteMatch, isTrue);
      expect(recommendation.needsConfirmation, isFalse);
      expect(recommendation.reasons, [
        DriverRecommendationReason.favoritePlace,
        DriverRecommendationReason.available,
      ]);
    });

    test('tier 0 is recommended, tier above 1 is not', () {
      expect(
        _map(ApiFixtures.driverRecommendation(tier: 0)).isRecommended,
        isTrue,
      );
      expect(
        _map(ApiFixtures.driverRecommendation(tier: 2)).isRecommended,
        isFalse,
      );
      expect(
        _map(ApiFixtures.driverRecommendation(tier: 3)).isRecommended,
        isFalse,
      );
    });

    test('schedule conflict blocks recommendation and needs confirmation', () {
      final recommendation = _map(
        ApiFixtures.driverRecommendation(
          hasConflict: true,
          hasFavoriteMatch: false,
        ),
      );

      expect(recommendation.hasScheduleConflict, isTrue);
      expect(recommendation.isRecommended, isFalse);
      expect(recommendation.needsConfirmation, isTrue);
      expect(recommendation.reasons, [
        DriverRecommendationReason.available,
        DriverRecommendationReason.scheduleConflict,
      ]);
    });

    test('unavailable driver is not available nor recommended', () {
      final recommendation = _map(
        ApiFixtures.driverRecommendation(
          tier: 0,
          isUnavailable: true,
          hasFavoriteMatch: false,
        ),
      );

      expect(recommendation.isAvailable, isFalse);
      expect(recommendation.isRecommended, isFalse);
      expect(recommendation.needsConfirmation, isTrue);
      expect(recommendation.reasons, [DriverRecommendationReason.unavailable]);
    });

    test('is_on_active_trip adds the chip and needs confirmation', () {
      final recommendation = _map(
        ApiFixtures.driverRecommendation(isOnActiveTrip: true),
      );

      expect(recommendation.isOnActiveTrip, isTrue);
      expect(recommendation.needsConfirmation, isTrue);
      expect(recommendation.isRecommended, isTrue);
      expect(recommendation.hasScheduleConflict, isFalse);
      expect(
        recommendation.reasons,
        contains(DriverRecommendationReason.onActiveTrip),
      );
    });

    test('unavailable favorite driver with conflict lists every reason', () {
      final recommendation = _map(
        ApiFixtures.driverRecommendation(
          isUnavailable: true,
          hasConflict: true,
        ),
      );

      expect(recommendation.reasons, [
        DriverRecommendationReason.favoritePlace,
        DriverRecommendationReason.unavailable,
        DriverRecommendationReason.scheduleConflict,
      ]);
    });
  });
}
