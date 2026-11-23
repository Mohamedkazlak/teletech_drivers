import 'package:flutter/foundation.dart';

/// Android or iOS device that can receive FCM.
enum DevicePlatform {
  android('android'),
  ios('ios');

  const DevicePlatform(this.wireValue);

  final String wireValue;

  static DevicePlatform get current {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? DevicePlatform.ios
        : DevicePlatform.android;
  }
}
