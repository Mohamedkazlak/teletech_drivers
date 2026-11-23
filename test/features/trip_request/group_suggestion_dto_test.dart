import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_dto_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/group_suggestion_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

import '../../support/api_fixtures.dart';

TripRequest _request(String id, {required String requestedAt}) {
  return TripRequestDtoMapper.toEntity(
    TripRequestDto.fromJson(
      ApiFixtures.tripRequest(id: id, requestedAt: requestedAt),
    ),
  );
}

void main() {
  group('GroupSuggestionDto.fromJson', () {
    test('parses a grouping suggestion', () {
      final dto = GroupSuggestionDto.fromJson(ApiFixtures.groupSuggestion());

      expect(dto.clusterId, 'cluster-1');
      expect(dto.requestIds, ['req-1', 'req-2']);
      expect(dto.destinationLabel, 'Airport');
      expect(dto.routeLabel, 'HQ → Airport');
      expect(dto.date, '2026-11-03');
      expect(dto.earliestRequestedAt, DateTime.utc(2026, 11, 3, 8));
      expect(dto.latestRequestedAt, DateTime.utc(2026, 11, 3, 9));
    });

    test('optional labels default and invalid request ids are dropped', () {
      final dto = GroupSuggestionDto.fromJson(
        ApiFixtures.groupSuggestion()
          ..remove('route_label')
          ..remove('destination_label')
          ..remove('date')
          ..['request_ids'] = ['req-1', '', 5, 'req-2'],
      );

      expect(dto.routeLabel, '');
      expect(dto.destinationLabel, isNull);
      expect(dto.date, isNull);
      expect(dto.requestIds, ['req-1', 'req-2']);
    });

    test('requires cluster id and timestamps', () {
      expect(
        () => GroupSuggestionDto.fromJson(
          ApiFixtures.groupSuggestion()..remove('cluster_id'),
        ),
        throwsFormatException,
      );
      expect(
        () => GroupSuggestionDto.fromJson(
          ApiFixtures.groupSuggestion()..remove('earliest_requested_at'),
        ),
        throwsFormatException,
      );
      expect(
        () => GroupSuggestionDto.fromJson(
          ApiFixtures.groupSuggestion()..['latest_requested_at'] = 'bad',
        ),
        throwsFormatException,
      );
    });
  });

  group('TripRequestDtoMapper.toGroupSuggestion', () {
    final dto = GroupSuggestionDto.fromJson(ApiFixtures.groupSuggestion());

    test('joins known requests sorted by requested time', () {
      final early = _request('req-1', requestedAt: '2026-11-03T08:00:00Z');
      final late = _request('req-2', requestedAt: '2026-11-03T09:00:00Z');

      final suggestion = TripRequestDtoMapper.toGroupSuggestion(
        dto: dto,
        requestsById: {'req-2': late, 'req-1': early},
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.clusterId, 'cluster-1');
      expect(suggestion.requests, [early, late]);
      expect(suggestion.size, 2);
      expect(suggestion.routeLabel, 'HQ → Airport');
      expect(suggestion.earliestDateTime, DateTime.utc(2026, 11, 3, 8));
      expect(suggestion.latestDateTime, DateTime.utc(2026, 11, 3, 9));
    });

    test('ignores unrelated known requests', () {
      final early = _request('req-1', requestedAt: '2026-11-03T08:00:00Z');
      final late = _request('req-2', requestedAt: '2026-11-03T09:00:00Z');
      final other = _request('req-3', requestedAt: '2026-11-03T08:30:00Z');

      final suggestion = TripRequestDtoMapper.toGroupSuggestion(
        dto: dto,
        requestsById: {'req-1': early, 'req-2': late, 'req-3': other},
      );

      expect(suggestion!.requests, [early, late]);
    });

    test('drops clusters with fewer than two known members', () {
      final early = _request('req-1', requestedAt: '2026-11-03T08:00:00Z');

      expect(
        TripRequestDtoMapper.toGroupSuggestion(
          dto: dto,
          requestsById: {'req-1': early},
        ),
        isNull,
      );
      expect(
        TripRequestDtoMapper.toGroupSuggestion(dto: dto, requestsById: {}),
        isNull,
      );
    });
  });
}
