import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_dto_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/place_snapshot_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

import '../../support/api_fixtures.dart';

void main() {
  group('TripRequestDto.fromJson', () {
    test('parses a full trip request resource', () {
      final json = ApiFixtures.tripRequest(status: 'approved', tripId: 't-9')
        ..['rejection_reason'] = 'n/a'
        ..['handled_by'] = 'admin-1'
        ..['handled_at'] = '2026-11-02T12:00:00Z'
        ..['auto_approved'] = true
        ..['suggested_group_id'] = 'grp-1'
        ..['requester_role'] = 'company_admin';

      final dto = TripRequestDto.fromJson(json);

      expect(dto.id, 'req-1');
      expect(dto.employeeId, 'emp-1');
      expect(dto.employeeNameEn, 'Sara Ali');
      expect(dto.employeeNameAr, 'سارة علي');
      expect(dto.employeePhone, '+201000000000');
      expect(dto.employeeBranch, Branch.companyHeadquarters);
      expect(dto.requesterRole, UserRole.companyAdmin);
      expect(dto.pickup.placeId, 'place-hq');
      expect(dto.pickup.name, 'HQ');
      expect(dto.pickup.lat, 30.05);
      expect(dto.pickup.lng, 31.23);
      expect(dto.pickup.address, 'Cairo');
      expect(dto.destination.placeId, 'place-airport');
      expect(dto.requestedAt, DateTime.utc(2026, 11, 3, 8));
      expect(dto.requestedAt.isUtc, isTrue);
      expect(dto.notes, 'Two bags');
      expect(dto.status, TripRequestStatus.approved);
      expect(dto.tripId, 't-9');
      expect(dto.rejectionReason, 'n/a');
      expect(dto.handledBy, 'admin-1');
      expect(dto.handledAt, DateTime.utc(2026, 11, 2, 12));
      expect(dto.autoApproved, isTrue);
      expect(dto.suggestedGroupId, 'grp-1');
      expect(dto.createdAt, DateTime.utc(2026, 11, 2, 10));
    });

    test('tolerates missing employee name, phone, branch and role', () {
      final json = ApiFixtures.tripRequest()
        ..remove('employee_name_en')
        ..remove('employee_name_ar')
        ..remove('employee_phone')
        ..remove('employee_branch')
        ..remove('requester_role')
        ..remove('notes');

      final dto = TripRequestDto.fromJson(json);

      expect(dto.employeeNameEn, isNull);
      expect(dto.employeeNameAr, isNull);
      expect(dto.employeePhone, isNull);
      expect(dto.employeeBranch, isNull);
      expect(dto.requesterRole, isNull);
      expect(dto.notes, '');
      expect(dto.autoApproved, isFalse);
      expect(dto.trip, isNull);
    });

    test('parses the nested trip block', () {
      final json = ApiFixtures.tripRequest()
        ..['trip'] = {
          'id': 'trip-9',
          'status': 'completed',
          'driver_name_en': 'Omar',
          'driver_name_ar': 'عمر',
          'confirmation_status': 'pending',
          'driver_showed_up': null,
        };

      final dto = TripRequestDto.fromJson(json);
      final trip = dto.trip;

      expect(trip, isNotNull);
      expect(trip!.id, 'trip-9');
      expect(trip.status, TripStatus.completed);
      expect(trip.driverNameEn, 'Omar');
      expect(trip.driverNameAr, 'عمر');
      expect(trip.confirmationStatus, TripConfirmationStatus.pending);
      expect(trip.driverShowedUp, isNull);

      final entity = TripRequestDtoMapper.toEntity(dto);
      expect(entity.linkedTrip?.needsReport, isTrue);
      expect(entity.linkedTrip?.localizedDriverName('ar'), 'عمر');
    });

    test('rejects malformed resources', () {
      expect(
        () => TripRequestDto.fromJson(ApiFixtures.tripRequest(id: '')),
        throwsFormatException,
      );
      expect(
        () => TripRequestDto.fromJson(
          ApiFixtures.tripRequest()..['status'] = 'bogus',
        ),
        throwsFormatException,
      );
      expect(
        () => TripRequestDto.fromJson(ApiFixtures.tripRequest()..['status'] = 3),
        throwsFormatException,
      );
      expect(
        () => TripRequestDto.fromJson(
          ApiFixtures.tripRequest()..remove('pickup'),
        ),
        throwsFormatException,
      );
      expect(
        () => TripRequestDto.fromJson(
          ApiFixtures.tripRequest()..['requested_at'] = 'not-a-date',
        ),
        throwsFormatException,
      );
    });
  });

  group('TripRequestDtoMapper.toEntity', () {
    test('maps every field onto the domain entity', () {
      final json = ApiFixtures.tripRequest(status: 'approved', tripId: 't-9')
        ..['handled_by'] = 'admin-1'
        ..['handled_at'] = '2026-11-02T12:00:00Z'
        ..['auto_approved'] = true
        ..['requester_role'] = 'drivers_admin'
        ..['suggested_group_id'] = 'grp-1';

      final entity = TripRequestDtoMapper.toEntity(
        TripRequestDto.fromJson(json),
      );

      expect(entity.id, 'req-1');
      expect(entity.employeeId, 'emp-1');
      expect(entity.employeeName, 'Sara Ali');
      expect(entity.employeeBranch, Branch.companyHeadquarters);
      expect(entity.employeePhone, '+201000000000');
      expect(entity.pickupPlaceId, 'place-hq');
      expect(entity.pickupPlaceName, 'HQ');
      expect(entity.pickupLat, 30.05);
      expect(entity.pickupLng, 31.23);
      expect(entity.pickupAddress, 'Cairo');
      expect(entity.destinationPlaceId, 'place-airport');
      expect(entity.destinationPlaceName, 'Airport');
      expect(entity.requestedDateTime, DateTime.utc(2026, 11, 3, 8));
      expect(entity.notes, 'Two bags');
      expect(entity.status, TripRequestStatus.approved);
      expect(entity.tripId, 't-9');
      expect(entity.handledByUid, 'admin-1');
      expect(entity.handledByName, isNull);
      expect(entity.handledAt, DateTime.utc(2026, 11, 2, 12));
      expect(entity.autoApproved, isTrue);
      expect(entity.requesterRole, 'driversAdmin');
      expect(entity.isAdminRequest, isTrue);
      expect(entity.suggestedGroupId, 'grp-1');
      expect(entity.createdAt, DateTime.utc(2026, 11, 2, 10));
      expect(entity.isAwaitingTrip, isFalse);
    });

    test('falls back to Arabic name, then empty string', () {
      final arabicOnly = TripRequestDto.fromJson(
        ApiFixtures.tripRequest()..remove('employee_name_en'),
      );
      expect(TripRequestDtoMapper.toEntity(arabicOnly).employeeName, 'سارة علي');

      final nameless = TripRequestDto.fromJson(
        ApiFixtures.tripRequest()
          ..remove('employee_name_en')
          ..remove('employee_name_ar')
          ..remove('employee_phone')
          ..remove('employee_branch'),
      );
      final entity = TripRequestDtoMapper.toEntity(nameless);
      expect(entity.employeeName, '');
      expect(entity.employeePhone, isNull);
      expect(entity.employeeBranch, isNull);
    });

    test('custom pin with null place_id is a custom location', () {
      final entity = TripRequestDtoMapper.toEntity(
        TripRequestDto.fromJson(
          ApiFixtures.tripRequest(
            pickup: {
              'place_id': null,
              'name': 'Pinned',
              'lat': 30.2,
              'lng': 31.4,
              'address': null,
            },
          ),
        ),
      );

      expect(entity.pickupPlaceId, isNull);
      expect(entity.pickupLat, 30.2);
      expect(entity.pickupAddress, isNull);
      expect(entity.hasCustomPickupLocation, isTrue);
      expect(entity.hasCustomDestinationLocation, isFalse);
    });

    test('approved request without trip is awaiting a trip', () {
      final entity = TripRequestDtoMapper.toEntity(
        TripRequestDto.fromJson(ApiFixtures.tripRequest(status: 'approved')),
      );
      expect(entity.isAwaitingTrip, isTrue);
      expect(entity.canCancel, isTrue);
    });
  });

  group('PlaceSnapshotDto.toCreateBody', () {
    test('approved place sends only place_id', () {
      const dto = PlaceSnapshotDto(
        placeId: 'place-hq',
        name: 'HQ',
        lat: 30,
        lng: 31,
        address: 'Cairo',
      );
      expect(dto.toCreateBody(), {'place_id': 'place-hq'});
    });

    test('null place_id sends custom pin fields', () {
      const dto = PlaceSnapshotDto(
        name: 'Pinned',
        lat: 30.2,
        lng: 31.4,
        address: 'Street 1',
      );
      expect(dto.toCreateBody(), {
        'name': 'Pinned',
        'lat': 30.2,
        'lng': 31.4,
        'address': 'Street 1',
      });
    });

    test('custom: prefix is never sent as place_id', () {
      const dto = PlaceSnapshotDto(
        placeId: 'custom:abc',
        name: 'Pinned',
        lat: 30.2,
        lng: 31.4,
      );
      final body = dto.toCreateBody();
      expect(body.containsKey('place_id'), isFalse);
      expect(body['name'], 'Pinned');
      expect(body['lat'], 30.2);
      expect(body['lng'], 31.4);
      expect(body.containsKey('address'), isFalse);
    });

    test('empty place_id is treated as custom', () {
      const dto = PlaceSnapshotDto(placeId: '', name: 'X', lat: 1, lng: 2);
      expect(dto.toCreateBody().containsKey('place_id'), isFalse);
    });

    test('toJson keeps every snapshot field', () {
      const dto = PlaceSnapshotDto(
        placeId: 'p',
        name: 'N',
        lat: 1,
        lng: 2,
        address: 'A',
      );
      expect(dto.toJson(), {
        'place_id': 'p',
        'name': 'N',
        'lat': 1.0,
        'lng': 2.0,
        'address': 'A',
      });
    });

    test('fromJson defaults name to empty and ignores blank strings', () {
      final dto = PlaceSnapshotDto.fromJson({
        'place_id': '  ',
        'address': '',
      });
      expect(dto.name, '');
      expect(dto.placeId, isNull);
      expect(dto.address, isNull);
    });
  });

  group('TripRequestStatusMapper', () {
    test('round-trips every status', () {
      for (final status in TripRequestStatus.values) {
        expect(
          TripRequestStatusMapper.fromApi(TripRequestStatusMapper.toApi(status)),
          status,
        );
      }
    });

    test('uses lowercase API strings and trims input', () {
      expect(TripRequestStatusMapper.toApi(TripRequestStatus.pending), 'pending');
      expect(
        TripRequestStatusMapper.fromApi(' approved '),
        TripRequestStatus.approved,
      );
    });

    test('unknown value throws FormatException', () {
      expect(() => TripRequestStatusMapper.fromApi('done'), throwsFormatException);
    });
  });
}
