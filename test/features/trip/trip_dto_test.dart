import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_dto_mapper.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_passenger_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

import '../../support/api_fixtures.dart';

void main() {
  group('TripDto.fromJson', () {
    test('parses a full trip with routes and start coordinates', () {
      final dto = TripDto.fromJson(ApiFixtures.trip(status: 'completed'));

      expect(dto.id, 'trip-1');
      expect(dto.driverId, 'drv-1');
      expect(dto.driver?.id, 'drv-1');
      expect(dto.scheduledAt, DateTime.utc(2026, 11, 3, 8));
      expect(dto.status, TripStatus.completed);
      expect(dto.createdBy, 'admin-1');
      expect(dto.pickupSummary, 'HQ');
      expect(dto.destinationSummary, 'Airport');
      expect(dto.goingStartedAt, DateTime.utc(2026, 11, 3, 8, 5));
      expect(dto.goingEndedAt, DateTime.utc(2026, 11, 3, 8, 45));
      expect(dto.returnStartedAt, DateTime.utc(2026, 11, 3, 9, 15));
      expect(dto.finishedAt, DateTime.utc(2026, 11, 3, 9, 55));
      expect(dto.goingDistanceM, 12500.5);
      expect(dto.returnDistanceM, 13000.0);
      expect(dto.totalDistanceM, 25500.5);
      expect(dto.startLat, 30.01);
      expect(dto.startLng, 31.02);
      expect(dto.goingRoute, '_p~iF~ps|U_ulLnnqC');
      expect(dto.returnRoute, '_mqNvxq`@');
      expect(dto.passengers, hasLength(1));
      expect(dto.requester?.id, 'emp-1');
      expect(dto.requester?.nameEn, 'Sara Ali');
      expect(dto.requester?.phone, '+201000000000');
      expect(dto.requesters, hasLength(1));
      expect(dto.passengerCount, 1);
      expect(dto.createdAt, DateTime.utc(2026, 11, 2, 10));
    });

    test('summary resource leaves route and start fields null', () {
      final dto = TripDto.fromJson(ApiFixtures.tripSummary());

      expect(dto.status, TripStatus.unassigned);
      expect(dto.driverId, isNull);
      expect(dto.driver, isNull);
      expect(dto.startLat, isNull);
      expect(dto.startLng, isNull);
      expect(dto.goingRoute, isNull);
      expect(dto.returnRoute, isNull);
      expect(dto.goingStartedAt, isNull);
      expect(dto.finishedAt, isNull);
      expect(dto.goingDistanceM, isNull);
      expect(dto.totalDistanceM, isNull);
    });

    test('missing passengers become an empty list', () {
      final dto = TripDto.fromJson(
        ApiFixtures.tripSummary()..remove('passengers'),
      );
      expect(dto.passengers, isEmpty);
    });

    test('missing requester fields stay empty and the count stays zero', () {
      final json = ApiFixtures.trip()
        ..remove('requester')
        ..remove('requesters')
        ..remove('passenger_count');
      final dto = TripDto.fromJson(json);
      expect(dto.requester, isNull);
      expect(dto.requesters, isEmpty);
      expect(dto.passengerCount, 0);
    });

    test('grouped requesters keep each phone and the server count', () {
      final dto = TripDto.fromJson(
        ApiFixtures.trip(
          passengers: [
            ApiFixtures.passenger(),
            ApiFixtures.passenger(
              employeeId: 'emp-2',
              requestId: 'req-2',
              nameEn: 'Omar Fathy',
              nameAr: 'عمر فتحي',
            ),
          ],
        ),
      );
      expect(dto.passengerCount, 2);
      expect(dto.requesters.map((item) => item.id), ['emp-1', 'emp-2']);
      expect(dto.requesters.map((item) => item.phone), [
        '+201000000000',
        '+201000000000',
      ]);
      expect(dto.requester?.id, 'emp-1');
    });

    test('rejects invalid resources', () {
      expect(
        () => TripDto.fromJson(ApiFixtures.trip(id: '')),
        throwsFormatException,
      );
      expect(
        () => TripDto.fromJson(ApiFixtures.trip()..['status'] = null),
        throwsFormatException,
      );
      expect(
        () => TripDto.fromJson(ApiFixtures.trip(status: 'flying')),
        throwsFormatException,
      );
      expect(
        () => TripDto.fromJson(ApiFixtures.trip()..remove('created_by')),
        throwsFormatException,
      );
      expect(
        () => TripDto.fromJson(ApiFixtures.trip()..['passengers'] = 'nope'),
        throwsFormatException,
      );
    });
  });

  group('TripPassengerDto.fromJson', () {
    test('parses names, branch and nested place snapshots', () {
      final dto = TripPassengerDto.fromJson(ApiFixtures.passenger());

      expect(dto.employeeId, 'emp-1');
      expect(dto.nameEn, 'Sara Ali');
      expect(dto.nameAr, 'سارة علي');
      expect(dto.phone, '+201000000000');
      expect(dto.branch, Branch.companyHeadquarters);
      expect(dto.requestId, 'req-1');
      expect(dto.pickup.placeId, 'place-hq');
      expect(dto.destination.name, 'Airport');
    });

    test('requires employee_id and request_id', () {
      expect(
        () => TripPassengerDto.fromJson(
          ApiFixtures.passenger()..remove('employee_id'),
        ),
        throwsFormatException,
      );
      expect(
        () => TripPassengerDto.fromJson(
          ApiFixtures.passenger()..remove('request_id'),
        ),
        throwsFormatException,
      );
    });
  });

  group('TripDtoMapper.toEntity', () {
    test('maps a full trip', () {
      final trip = TripDtoMapper.toEntity(
        TripDto.fromJson(ApiFixtures.trip(status: 'completed')),
      );

      expect(trip.id, 'trip-1');
      expect(trip.driverId, 'drv-1');
      expect(trip.status, TripStatus.completed);
      expect(trip.scheduledAt, DateTime.utc(2026, 11, 3, 8));
      expect(trip.createdBy, 'admin-1');
      expect(trip.createdAt, DateTime.utc(2026, 11, 2, 10));
      expect(trip.goingStartedAt, DateTime.utc(2026, 11, 3, 8, 5));
      expect(trip.goingEndedAt, DateTime.utc(2026, 11, 3, 8, 45));
      expect(trip.returnStartedAt, DateTime.utc(2026, 11, 3, 9, 15));
      expect(trip.finishedAt, DateTime.utc(2026, 11, 3, 9, 55));
      expect(trip.startLat, 30.01);
      expect(trip.startLng, 31.02);
      expect(trip.hasStartCoordinates, isTrue);
      expect(trip.goingDistanceMeters, 12500.5);
      expect(trip.returnDistanceMeters, 13000.0);
      expect(trip.totalDistanceMeters, 25500.5);
      expect(trip.goingRoute, '_p~iF~ps|U_ulLnnqC');
      expect(trip.returnRoute, '_mqNvxq`@');
    });

    test('maps a summary with null route and start fields', () {
      final trip = TripDtoMapper.toEntity(
        TripDto.fromJson(ApiFixtures.tripSummary()),
      );

      expect(trip.driverId, isNull);
      expect(trip.startLat, isNull);
      expect(trip.startLng, isNull);
      expect(trip.hasStartCoordinates, isFalse);
      expect(trip.goingRoute, isNull);
      expect(trip.returnRoute, isNull);
      expect(trip.goingDistanceMeters, isNull);
      expect(trip.status, TripStatus.unassigned);
    });

    test('passengers map to requestIds, names, ids and branches', () {
      final trip = TripDtoMapper.toEntity(
        TripDto.fromJson(
          ApiFixtures.trip(
            passengers: [
              ApiFixtures.passenger(),
              ApiFixtures.passenger(
                employeeId: 'emp-2',
                requestId: 'req-2',
                nameEn: null,
                branch: 'new_headquarters',
              ),
              ApiFixtures.passenger(
                employeeId: 'emp-3',
                requestId: 'req-3',
                nameEn: null,
                nameAr: null,
                branch: null,
              ),
              ApiFixtures.passenger(
                employeeId: 'emp-4',
                requestId: 'req-4',
                nameEn: 'Dina',
                branch: 'company_headquarters',
              ),
            ],
          ),
        ),
      );

      expect(trip.requestIds, ['req-1', 'req-2', 'req-3', 'req-4']);
      expect(trip.passengerIds, ['emp-1', 'emp-2', 'emp-3', 'emp-4']);
      expect(trip.passengerNames, ['Sara Ali', 'سارة علي', '', 'Dina']);
      expect(trip.passengerBranches, [
        Branch.companyHeadquarters,
        Branch.newHeadquarters,
        null,
        Branch.companyHeadquarters,
      ]);
      expect(trip.branches, [
        Branch.companyHeadquarters,
        Branch.newHeadquarters,
      ]);
      expect(trip.passengerCount, 4);
      expect(trip.requesters.map((item) => item.id), [
        'emp-1',
        'emp-2',
        'emp-3',
        'emp-4',
      ]);
    });

    test('uses the Arabic name when the locale is Arabic', () {
      final trip = TripDtoMapper.toEntity(TripDto.fromJson(ApiFixtures.trip()));
      expect(trip.requesters.single.localizedName('ar'), 'سارة علي');
      expect(trip.requesters.single.localizedName('en'), 'Sara Ali');
    });

    test('trip with no passengers has empty parallel lists', () {
      final trip = TripDtoMapper.toEntity(
        TripDto.fromJson(ApiFixtures.trip(passengers: const [])),
      );
      expect(trip.requestIds, isEmpty);
      expect(trip.passengerNames, isEmpty);
      expect(trip.passengerBranches, isEmpty);
    });
  });

  group('TripStatusMapper', () {
    test('round-trips every status', () {
      for (final status in TripStatus.values) {
        expect(
          TripStatusMapper.fromApi(TripStatusMapper.toApi(status)),
          status,
        );
      }
    });

    test('at_destination uses snake_case on the wire', () {
      expect(
        TripStatusMapper.toApi(TripStatus.atDestination),
        'at_destination',
      );
      expect(
        TripStatusMapper.fromApi('at_destination'),
        TripStatus.atDestination,
      );
    });

    test('legacy started maps to going and input is trimmed', () {
      expect(TripStatusMapper.fromApi('started'), TripStatus.going);
      expect(TripStatusMapper.fromApi(' returning '), TripStatus.returning);
    });

    test('unknown value throws FormatException', () {
      expect(() => TripStatusMapper.fromApi('paused'), throwsFormatException);
    });
  });
}
