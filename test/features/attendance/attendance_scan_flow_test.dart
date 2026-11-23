import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/attendance/domain/services/attendance_scan_flow.dart';

void main() {
  const flow = AttendanceScanFlow();
  const fix = AttendanceFix(lat: 1, lng: 2, accuracyM: 8, isMocked: false);

  test('permission denied stops before the camera', () async {
    var scanned = false;
    final result = await flow.run(
      locate: () async => const AttendanceLocateDenied(),
      scan: () async {
        scanned = true;
        return 'qr';
      },
      submit: (_, _) async {},
    );
    expect(result.step, AttendanceScanStep.permissionDenied);
    expect(scanned, isFalse);
  });

  test('gps off stops before the camera', () async {
    final result = await flow.run(
      locate: () async => const AttendanceLocateGpsOff(),
      scan: () async => 'qr',
      submit: (_, _) async {},
    );
    expect(result.step, AttendanceScanStep.gpsOff);
  });

  test('a cancelled scan is not submitted', () async {
    var submitted = false;
    final result = await flow.run(
      locate: () async => const AttendanceLocateReady(fix),
      scan: () async => null,
      submit: (_, _) async {
        submitted = true;
      },
    );
    expect(result.step, AttendanceScanStep.cancelled);
    expect(submitted, isFalse);
  });

  test('a successful scan submits the fix and payload', () async {
    AttendanceFix? sent;
    String? payload;
    final result = await flow.run(
      locate: () async => const AttendanceLocateReady(fix),
      scan: () async => ' telecars-attendance:v1:abc ',
      submit: (value, qr) async {
        sent = value;
        payload = qr;
      },
    );
    expect(result.step, AttendanceScanStep.success);
    expect(sent, same(fix));
    expect(payload, 'telecars-attendance:v1:abc');
  });

  test('server error codes keep the distance', () async {
    final result = await flow.run(
      locate: () async => const AttendanceLocateReady(fix),
      scan: () async => 'qr',
      submit: (_, _) async {
        throw const AttendanceFailure(
          code: 'outside_radius',
          distanceM: 180,
          radiusM: 150,
        );
      },
    );
    expect(result.step, AttendanceScanStep.failed);
    expect(result.code, 'outside_radius');
    expect(result.distanceM, 180);
    expect(result.radiusM, 150);
  });
}
