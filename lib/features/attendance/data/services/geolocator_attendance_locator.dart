import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:teletech_drivers/features/attendance/domain/services/attendance_scan_flow.dart';

/// High-accuracy fix for an attendance scan. Mocked fixes are reported, not hidden.
class GeolocatorAttendanceLocator {
  const GeolocatorAttendanceLocator();

  Future<AttendanceLocateResult> locate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return const AttendanceLocateGpsOff();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever)) {
      final status = await ph.Permission.locationWhenInUse.request();
      if (status.isGranted || status.isLimited) {
        permission = LocationPermission.whileInUse;
      } else if (status.isPermanentlyDenied) {
        permission = LocationPermission.deniedForever;
      }
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const AttendanceLocateDenied();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return AttendanceLocateReady(
      AttendanceFix(
        lat: position.latitude,
        lng: position.longitude,
        accuracyM: position.accuracy,
        isMocked: position.isMocked,
      ),
    );
  }
}
