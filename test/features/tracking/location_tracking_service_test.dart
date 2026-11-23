import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teletech_drivers/features/tracking/data/services/geolocator_location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('provider shares the mocked position source', () {
    final source = _FakeLocationSource();
    final container = ProviderContainer(
      overrides: [locationSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);

    final service =
        container.read(locationTrackingServiceProvider)
            as GeolocatorLocationTrackingService;

    expect(service.locationSource, same(source));
  });

  test('active trip keeps the last fix when GPS fails and ignores points after stop', () async {
    final source = _FakeLocationSource();
    final service = GeolocatorLocationTrackingService(
      locationSource: source,
      permissionGate: () async => LocationPermissionOutcome.granted,
    );
    addTearDown(service.dispose);

    await service.startTracking(tripId: 'trip-1', phase: TripTrackPhase.going);

    expect(source.distanceFilters, [0]);
    source.emit(_position(latitude: 30.0));
    await Future<void>.delayed(Duration.zero);

    expect(service.latestPosition?.latitude, 30);
    expect(service.acceptedPoints, hasLength(1));
    expect(service.locationError, isNull);
    expect(service.isTracking, isTrue);

    source.fail(StateError('gps lost'));
    await Future<void>.delayed(Duration.zero);

    expect(service.locationError, isA<StateError>());
    expect(service.latestPosition?.latitude, 30);
    expect(service.acceptedPoints, hasLength(1));

    await service.stopTracking();
    source.emit(_position(latitude: 31));
    await Future<void>.delayed(Duration.zero);

    expect(service.isTracking, isFalse);
    expect(service.latestPosition?.latitude, 30);
    expect(service.acceptedPoints, isEmpty);
  });
}

Position _position({required double latitude}) {
  return Position(
    latitude: latitude,
    longitude: 31,
    timestamp: DateTime.utc(2026, 11, 11, 8),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 10,
    headingAccuracy: 0,
    speed: 3,
    speedAccuracy: 0,
  );
}

class _FakeLocationSource implements LocationSource {
  final _events = StreamController<Position>.broadcast();
  final distanceFilters = <int>[];
  Position? current;

  void emit(Position position) {
    current = position;
    _events.add(position);
  }

  void fail(Object error) {
    _events.addError(error);
  }

  @override
  Position? get cachedPosition => current;

  @override
  Stream<Position> watchPositions({required int distanceFilterMeters}) {
    distanceFilters.add(distanceFilterMeters);
    return _events.stream;
  }

  @override
  Future<Position?> getLastKnownPosition() async => current;

  @override
  Future<Position?> getCurrentPosition({required Duration timeout}) async {
    return current;
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}
