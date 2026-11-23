import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/router/app_router.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/push/presentation/push_session.dart';
import 'package:teletech_drivers/features/realtime/presentation/providers/realtime_providers.dart';

/// Root widget: theme, localization, and routing.
class TeleTechApp extends ConsumerWidget {
  const TeleTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);
    watchRealtimeSession(ref);
    watchPushSession(ref);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TeleCars',
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
    );
  }
}
