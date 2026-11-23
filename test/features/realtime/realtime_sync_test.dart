import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/realtime/domain/services/realtime_channels.dart';
import 'package:teletech_drivers/features/realtime/domain/services/realtime_refresh_plan.dart';

AppUser _user(UserRole role) {
  return AppUser(
    id: 'user-1',
    name: 'Test',
    email: 'test@example.com',
    role: role,
  );
}

void main() {
  test('staff subscribe to their role channel and their own user channel', () {
    expect(channelsForUser(_user(UserRole.companyAdmin)), [
      'private-role.company-admin',
      'private-user.user-1',
    ]);
    expect(channelsForUser(_user(UserRole.admin)), [
      'private-role.admin',
      'private-user.user-1',
    ]);
    expect(channelsForUser(_user(UserRole.driversAdmin)), [
      'private-role.drivers-admin',
      'private-user.user-1',
    ]);
  });

  test('a driver or employee only joins their own channel', () {
    expect(channelsForUser(_user(UserRole.driver)), ['private-user.user-1']);
    expect(channelsForUser(_user(UserRole.employee)), ['private-user.user-1']);
  });

  test('a new trip request refreshes request and trip providers', () {
    expect(scopesForRealtimeEvent('trip-request.created'), {
      RealtimeScope.tripRequests,
      RealtimeScope.trips,
    });
  });

  test('an approval refreshes trip providers', () {
    expect(
      scopesForRealtimeEvent('trip.assigned'),
      contains(RealtimeScope.trips),
    );
    expect(
      scopesForRealtimeEvent('trip.confirmed'),
      contains(RealtimeScope.tripRequests),
    );
  });

  test('attendance and location events refresh their own providers', () {
    expect(scopesForRealtimeEvent('attendance.checked_in'), {
      RealtimeScope.attendance,
    });
    expect(scopesForRealtimeEvent('driver-location.updated'), {
      RealtimeScope.liveMap,
    });
  });
}
