import 'package:teletech_drivers/core/errors/failures.dart';

/// GPS sample taken at the moment a QR is scanned.
class AttendanceFix {
  const AttendanceFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.isMocked,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final bool isMocked;
}

sealed class AttendanceLocateResult {
  const AttendanceLocateResult();
}

final class AttendanceLocateReady extends AttendanceLocateResult {
  const AttendanceLocateReady(this.fix);

  final AttendanceFix fix;
}

final class AttendanceLocateDenied extends AttendanceLocateResult {
  const AttendanceLocateDenied();
}

final class AttendanceLocateGpsOff extends AttendanceLocateResult {
  const AttendanceLocateGpsOff();
}

/// No fix arrived in time and none was cached (indoors, emulator, weak GPS).
final class AttendanceLocateUnavailable extends AttendanceLocateResult {
  const AttendanceLocateUnavailable();
}

enum AttendanceScanStep {
  permissionDenied,
  gpsOff,
  locationUnavailable,
  cancelled,
  success,
  failed,
}

class AttendanceScanResult {
  const AttendanceScanResult({
    required this.step,
    this.code,
    this.distanceM,
    this.radiusM,
  });

  final AttendanceScanStep step;
  final String? code;
  final int? distanceM;
  final int? radiusM;
}

/// Reads a location, then a QR, then submits both. Camera and GPS are injected.
class AttendanceScanFlow {
  const AttendanceScanFlow();

  Future<AttendanceScanResult> run({
    required Future<AttendanceLocateResult> Function() locate,
    required Future<String?> Function() scan,
    required Future<void> Function(AttendanceFix fix, String qrPayload) submit,
  }) async {
    final located = await locate();
    switch (located) {
      case AttendanceLocateDenied():
        return const AttendanceScanResult(
          step: AttendanceScanStep.permissionDenied,
        );
      case AttendanceLocateGpsOff():
        return const AttendanceScanResult(step: AttendanceScanStep.gpsOff);
      case AttendanceLocateUnavailable():
        return const AttendanceScanResult(
          step: AttendanceScanStep.locationUnavailable,
        );
      case AttendanceLocateReady(:final fix):
        final payload = await scan();
        if (payload == null || payload.trim().isEmpty) {
          return const AttendanceScanResult(step: AttendanceScanStep.cancelled);
        }
        try {
          await submit(fix, payload.trim());
          return const AttendanceScanResult(step: AttendanceScanStep.success);
        } on AttendanceFailure catch (failure) {
          return AttendanceScanResult(
            step: AttendanceScanStep.failed,
            code: failure.code,
            distanceM: failure.distanceM,
            radiusM: failure.radiusM,
          );
        }
    }
  }
}
