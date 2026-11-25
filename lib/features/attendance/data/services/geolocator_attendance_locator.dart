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

    // A fresh fix can take a long time indoors (or never arrive on an
    // emulator), so cap the wait and fall back to the last known position.
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } on Object {
      position = null;
    }
    position ??= await _lastKnown();
    if (position == null) return const AttendanceLocateUnavailable();
    return AttendanceLocateReady(
      AttendanceFix(
        lat: position.latitude,
        lng: position.longitude,
        accuracyM: position.accuracy,
        isMocked: position.isMocked,
      ),
    );
  }

  Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } on Object {
      return null;
    }
  }
}
