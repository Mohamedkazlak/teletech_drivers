import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/app.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/localization/locale_store.dart';
import 'package:teletech_drivers/features/push/data/firebase_push_setup.dart';
import 'package:teletech_drivers/features/push/presentation/providers/push_providers.dart';
import 'package:teletech_drivers/features/realtime/presentation/providers/realtime_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = await LocaleStore.read();
  final pushGateway = await tryCreateFirebasePushGateway();
  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(locale),
        realtimeClientProvider.overrideWith(buildPusherRealtimeClient),
        if (pushGateway != null)
          pushMessagingGatewayProvider.overrideWithValue(pushGateway),
      ],
      child: const TeleTechApp(),
    ),
  );
}
