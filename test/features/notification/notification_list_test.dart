import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/presentation/widgets/notification_list_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final unread = AppNotification(
    id: 'n1',
    type: AppNotificationType.requestSubmitted,
    titleKey: 'notifications.request_submitted.title',
    bodyKey: 'notifications.request_submitted.body',
    params: const {
      'requester_name_en': 'Mona',
      'requester_name_ar': 'منى',
      'pickup': 'HQ',
      'destination': 'Site',
    },
    createdAt: DateTime.utc(2026, 11, 16, 10),
  );
  final read = AppNotification(
    id: 'n2',
    type: AppNotificationType.tripAssigned,
    titleKey: 'notifications.trip_assigned.title',
    bodyKey: 'notifications.trip_assigned.body',
    params: const {
      'driver_name_en': 'Nader',
      'driver_name_ar': 'نادر',
      'pickup': 'HQ',
      'destination': 'Site',
    },
    createdAt: DateTime.utc(2026, 11, 16, 11),
    readAt: DateTime.utc(2026, 11, 16, 12),
  );

  Future<void> pumpList(
    WidgetTester tester, {
    required Locale locale,
    required ValueChanged<AppNotification> onOpen,
    required VoidCallback onMarkAll,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: NotificationListBody(
            items: [unread, read],
            onOpen: onOpen,
            onMarkAll: onMarkAll,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('highlights unread rows and marks them from a tap', (tester) async {
    AppNotification? opened;
    var markedAll = false;
    await pumpList(
      tester,
      locale: const Locale('en'),
      onOpen: (item) => opened = item,
      onMarkAll: () => markedAll = true,
    );

    expect(find.text('New trip request'), findsOneWidget);
    expect(
      find.text('Mona requested a trip from HQ to Site.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Material>(find.byKey(const Key('notification-n1'))).color,
      AppColors.paleBlue,
    );
    expect(
      tester.widget<Material>(find.byKey(const Key('notification-n2'))).color,
      AppColors.white,
    );

    await tester.tap(find.text('New trip request'));
    await tester.pump();
    expect(opened?.id, 'n1');

    await tester.tap(find.text('Mark all as read'));
    await tester.pump();
    expect(markedAll, isTrue);
  });

  testWidgets('renders Arabic copy from the body key', (tester) async {
    await pumpList(
      tester,
      locale: const Locale('ar'),
      onOpen: (_) {},
      onMarkAll: () {},
    );

    expect(find.text('طلب رحلة جديد'), findsOneWidget);
    expect(find.text('طلب منى رحلة من HQ إلى Site.'), findsOneWidget);
    expect(find.text('تعليم الكل كمقروء'), findsOneWidget);
  });
}
