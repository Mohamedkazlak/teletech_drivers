import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:teletech_drivers/features/push/data/firebase_push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';

/// Starts Firebase only when native config is present. A missing
/// google-services file or GoogleService-Info.plist must not crash startup.
Future<PushMessagingGateway?> tryCreateFirebasePushGateway() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Firebase config is absent; push notifications are disabled. $error\n$stackTrace',
    );
    return null;
  }
  return FirebasePushMessagingGateway();
}
