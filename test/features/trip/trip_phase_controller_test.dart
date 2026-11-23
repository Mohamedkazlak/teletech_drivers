import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/trip/domain/controllers/trip_phase_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

void main() {
  const controller = TripPhaseController();

  group('TripPhaseController allowed transitions', () {
    test('assigned → going is allowed', () {
      expect(controller.canStartTrip(TripStatus.assigned), isTrue);
      expect(
        controller.canTransition(TripStatus.assigned, TripStatus.going),
        isTrue,
      );
    });

    test('cannot start returning before going has ended', () {
      expect(
        controller.canTransition(TripStatus.going, TripStatus.returning),
        isFalse,
      );
      expect(controller.canStartReturn(TripStatus.going), isFalse);
      expect(controller.canStartReturn(TripStatus.atDestination), isTrue);
    });

    test('going → atDestination → returning → completed', () {
      expect(controller.canArriveAtDestination(TripStatus.going), isTrue);
      expect(controller.canStartReturn(TripStatus.atDestination), isTrue);
      expect(controller.canEndTrip(TripStatus.returning), isTrue);
    });

    test('cannot skip from assigned to completed', () {
      expect(
        controller.canTransition(TripStatus.assigned, TripStatus.completed),
        isFalse,
      );
      expect(
        () => controller.ensureCanTransition(
          TripStatus.assigned,
          TripStatus.completed,
        ),
        throwsA(isA<InvalidStateFailure>()),
      );
    });

    test('the phase button is available while going and while returning', () {
      expect(controller.actionFor(TripStatus.going), isNotNull);
      expect(controller.actionFor(TripStatus.returning), isNotNull);
      expect(
        controller.actionFor(TripStatus.going),
        TripPhaseAction.arriveAtDestination,
      );
      expect(
        controller.actionFor(TripStatus.returning),
        TripPhaseAction.endTrip,
      );
      expect(controller.canEndTrip(TripStatus.returning), isTrue);
      expect(controller.actionFor(TripStatus.completed), isNull);
    });

    test('actionFor maps status to the next driver button', () {
      expect(
        controller.actionFor(TripStatus.assigned),
        TripPhaseAction.startTrip,
      );
      expect(
        controller.actionFor(TripStatus.going),
        TripPhaseAction.arriveAtDestination,
      );
      expect(
        controller.actionFor(TripStatus.atDestination),
        TripPhaseAction.startReturn,
      );
      expect(
        controller.actionFor(TripStatus.returning),
        TripPhaseAction.endTrip,
      );
      expect(controller.actionFor(TripStatus.completed), isNull);
    });
  });
}
