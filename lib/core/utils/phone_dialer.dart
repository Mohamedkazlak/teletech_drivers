import 'package:flutter/services.dart';

/// Opens the platform dialer for [phone] without adding a launcher package.
abstract final class PhoneDialer {
  static const _channel = MethodChannel('com.teletech.teletech_drivers/dialer');

  static Future<void> dial(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return;
    await _channel.invokeMethod<void>('dial', trimmed);
  }
}
