import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';
import 'package:teletech_drivers/features/push/domain/push_destination.dart';

void main() {
  PushMessage message({
    required String type,
    String? tripId,
    String? tripRequestId,
  }) {
    return PushMessage.fromData(
      {
        ApiJsonKeys.notificationId: 'n1',
        ApiJsonKeys.type: type,
        ApiJsonKeys.tripId: tripId ?? '',
        ApiJsonKeys.tripRequestId: tripRequestId ?? '',
      },
      title: 'Title',
      body: 'Body',
    )!;
  }

  test(
    'maps a push payload onto the same screens as an in-app notification',
    () {
      expect(
        pushLocation(
          role: UserRole.companyAdmin,
          message: message(type: 'request_submitted', tripRequestId: 'req-1'),
        ),
        '${AppRoutes.companyAdminHome}?request=req-1',
      );
      expect(
        pushLocation(
          role: UserRole.driversAdmin,
          message: message(
            type: 'trip_ready_to_assign',
            tripRequestId: 'req-2',
          ),
        ),
        '${AppRoutes.driversAdminHome}?request=req-2',
      );
      expect(
        pushLocation(
          role: UserRole.driver,
          message: message(type: 'trip_assigned', tripId: 'trip-1'),
        ),
        AppRoutes.driverTripDetailsPath('trip-1'),
      );
      expect(
        pushLocation(
          role: UserRole.employee,
          message: message(
            type: 'trip_ended_report_needed',
            tripId: 'trip-2',
            tripRequestId: 'req-3',
          ),
        ),
        '${AppRoutes.employeeTripRequestPath('req-3')}?report=1',
      );
      expect(
        pushLocation(
          role: UserRole.companyAdmin,
          message: message(type: 'own_trip_assigned', tripId: 'trip-4'),
        ),
        AppRoutes.companyAdminTripDetailsPath('trip-4'),
      );
    },
  );

  test('a payload without a destination does not open a screen', () {
    expect(
      pushLocation(
        role: UserRole.employee,
        message: message(type: 'request_submitted'),
      ),
      isNull,
    );
    expect(
      pushLocation(
        role: UserRole.driver,
        message: message(type: 'not_a_type', tripId: 'trip-1'),
      ),
      isNull,
    );
    expect(PushMessage.fromData({ApiJsonKeys.type: 'trip_assigned'}), isNull);
  });
}
