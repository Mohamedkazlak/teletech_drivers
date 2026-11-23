import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/polyline_encoder.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_dto_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_report_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

import '../../support/api_fixtures.dart';

void main() {
  const goingPoints = [
    RoutePoint(38.5, -120.2),
    RoutePoint(40.7, -120.95),
    RoutePoint(43.252, -126.453),
  ];
  const returnPoints = [RoutePoint(43.252, -126.453), RoutePoint(38.5, -120.2)];

  group('TripReportDto.fromJson', () {
    test('parses durations, distances and timestamps', () {
      final dto = TripReportDto.fromJson(ApiFixtures.tripReport());

      expect(dto.status, TripStatus.completed);
      expect(dto.isInProgress, isFalse);
      expect(dto.start, DateTime.utc(2026, 11, 3, 8, 5));
      expect(dto.finish, DateTime.utc(2026, 11, 3, 9, 55));
      expect(dto.goingDurationSeconds, 2400);
      expect(dto.waitingDurationSeconds, 1800);
      expect(dto.returnDurationSeconds, 2400);
      expect(dto.totalDurationSeconds, 6600);
      expect(dto.goingDistanceKm, 12.5);
      expect(dto.returnDistanceKm, 13.0);
      expect(dto.totalDistanceKm, 25.5);
    });

    test('in-progress report leaves later fields null', () {
      final dto = TripReportDto.fromJson({
        'status': 'going',
        'is_in_progress': true,
        'start': '2026-11-03T08:05:00Z',
      });

      expect(dto.status, TripStatus.going);
      expect(dto.isInProgress, isTrue);
      expect(dto.finish, isNull);
      expect(dto.totalDurationSeconds, isNull);
      expect(dto.goingDistanceKm, isNull);
      expect(dto.goingRoute, isNull);
    });

    test('integer km values become doubles', () {
      final dto = TripReportDto.fromJson(
        ApiFixtures.tripReport()..['going_distance_km'] = 12,
      );
      expect(dto.goingDistanceKm, 12.0);
      expect(dto.goingDistanceKm, isA<double>());
    });

    test('invalid status throws FormatException', () {
      expect(
        () => TripReportDto.fromJson({'status': 7, 'is_in_progress': false}),
        throwsFormatException,
      );
      expect(
        () => TripReportDto.fromJson({
          'status': 'bogus',
          'is_in_progress': false,
        }),
        throwsFormatException,
      );
    });
  });

  group('TripDtoMapper.toReport', () {
    test('converts seconds to Duration and keeps km values', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson(ApiFixtures.tripReport()),
      );

      expect(report.status, TripStatus.completed);
      expect(report.isInProgress, isFalse);
      expect(report.startedAt, DateTime.utc(2026, 11, 3, 8, 5));
      expect(report.finishedAt, DateTime.utc(2026, 11, 3, 9, 55));
      expect(report.goingDuration, const Duration(minutes: 40));
      expect(report.waitingDuration, const Duration(minutes: 30));
      expect(report.returnDuration, const Duration(minutes: 40));
      expect(report.totalDuration, const Duration(minutes: 110));
      expect(report.goingDistanceKm, 12.5);
      expect(report.returnDistanceKm, 13.0);
      expect(report.totalDistanceKm, 25.5);
    });

    test('missing durations stay null', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson({'status': 'going', 'is_in_progress': true}),
      );

      expect(report.totalDuration, isNull);
      expect(report.goingDuration, isNull);
      expect(report.waitingDuration, isNull);
      expect(report.returnDuration, isNull);
      expect(report.hasRouteGeometry, isFalse);
    });

    test('decodes polylines into route points with markers', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson(
          ApiFixtures.tripReport()
            ..['going_route'] = PolylineEncoder.encode(goingPoints)
            ..['return_route'] = PolylineEncoder.encode(returnPoints),
        ),
      );

      expect(report.goingPoints, hasLength(3));
      for (var i = 0; i < goingPoints.length; i++) {
        expect(report.goingPoints[i].lat, closeTo(goingPoints[i].lat, 1e-5));
        expect(report.goingPoints[i].lng, closeTo(goingPoints[i].lng, 1e-5));
      }
      expect(report.returnPoints, hasLength(2));
      expect(report.startMarker, report.goingPoints.first);
      expect(report.destinationMarker, report.goingPoints.last);
      expect(report.hasRouteGeometry, isTrue);
    });

    test('decodes the canonical polyline example', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson(
          ApiFixtures.tripReport()..['return_route'] = null,
        ),
      );

      expect(report.goingPoints, hasLength(3));
      expect(report.goingPoints.first.lat, closeTo(38.5, 1e-5));
      expect(report.goingPoints.first.lng, closeTo(-120.2, 1e-5));
      expect(report.goingPoints.last.lat, closeTo(43.252, 1e-5));
      expect(report.goingPoints.last.lng, closeTo(-126.453, 1e-5));
      expect(report.returnPoints, isEmpty);
    });

    test('destination marker falls back to first return point', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson(
          ApiFixtures.tripReport()
            ..['going_route'] = null
            ..['return_route'] = PolylineEncoder.encode(returnPoints),
        ),
      );

      expect(report.goingPoints, isEmpty);
      expect(report.startMarker, isNull);
      expect(report.destinationMarker?.lat, closeTo(43.252, 1e-5));
      expect(report.hasRouteGeometry, isTrue);
    });

    test('empty route strings produce no points or markers', () {
      final report = TripDtoMapper.toReport(
        TripReportDto.fromJson(
          ApiFixtures.tripReport()
            ..['going_route'] = ''
            ..['return_route'] = '',
        ),
      );

      expect(report.goingPoints, isEmpty);
      expect(report.returnPoints, isEmpty);
      expect(report.startMarker, isNull);
      expect(report.destinationMarker, isNull);
    });
  });
}
