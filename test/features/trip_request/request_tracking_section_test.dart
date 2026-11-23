import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/utils/localized_place_name.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_tracking_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('pending request answers approval as still pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: RequestTrackingSection(
          tracking: _tracking(stage: RequestTrackingStage.submitted),
        ),
      ),
    );

    expect(find.text('Approved?'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);
    expect(find.text('Driver assigned?'), findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
  });

  testWidgets('assigned request shows the driver name and phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: RequestTrackingSection(
          tracking: _tracking(
            stage: RequestTrackingStage.driverAssigned,
            driver: const RequestTrackingDriver(
              nameEn: 'Nader Hassan',
              nameAr: 'نادر حسن',
              phone: '01099998888',
            ),
            vehicle: const RequestTrackingVehicle(carLicense: 'PLATE-9'),
            reached: {RequestTrackingStage.driverAssigned},
          ),
        ),
      ),
    );

    expect(find.textContaining('Nader Hassan'), findsWidgets);
    expect(find.textContaining('01099998888'), findsWidgets);
    expect(find.textContaining('PLATE-9'), findsOneWidget);
    expect(find.text('Not yet'), findsNothing);
  });

  testWidgets('rejected request shows the reason', (tester) async {
    await tester.pumpWidget(
      _app(
        child: RequestTrackingSection(
          tracking: _tracking(
            stage: RequestTrackingStage.rejected,
            rejectionReason: 'No cars that day',
            timeline: const [
              RequestTrackingEvent(
                stage: RequestTrackingStage.submitted,
                actorRole: UserRole.employee,
              ),
              RequestTrackingEvent(
                stage: RequestTrackingStage.rejected,
                actorRole: UserRole.companyAdmin,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Rejection reason'), findsOneWidget);
    expect(find.text('No cars that day'), findsOneWidget);
  });

  testWidgets('My Trips card uses the tracking chip', (tester) async {
    await tester.pumpWidget(
      _app(
        child: TripRequestCard(
          request: _request(
            _tracking(stage: RequestTrackingStage.driverAssigned),
          ),
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('Driver assigned'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });
}

Widget _app({required Widget child}) {
  return ProviderScope(
    overrides: [
      placeNameResolverProvider.overrideWithValue(PlaceNameResolver(const [])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

TripRequest _request(RequestTracking tracking) {
  return TripRequest(
    id: 'req-1',
    employeeId: 'emp-1',
    employeeName: 'Sara Ali',
    pickupPlaceName: 'HQ',
    destinationPlaceName: 'Airport',
    requestedDateTime: DateTime.utc(2026, 11, 4, 8),
    notes: '',
    status: TripRequestStatus.approved,
    createdAt: DateTime.utc(2026, 11, 2, 10),
    tracking: tracking,
  );
}

RequestTracking _tracking({
  required RequestTrackingStage stage,
  RequestTrackingDriver? driver,
  RequestTrackingVehicle? vehicle,
  String? rejectionReason,
  Set<RequestTrackingStage> reached = const {
    RequestTrackingStage.submitted,
  },
  List<RequestTrackingEvent>? timeline,
}) {
  final submittedAt = DateTime.utc(2026, 11, 2, 10);
  return RequestTracking(
    stage: stage,
    rejectionReason: rejectionReason,
    driver: driver,
    scheduledAt: DateTime.utc(2026, 11, 4, 8),
    vehicle: vehicle,
    timeline:
        timeline ??
        [
          for (final step in [
            RequestTrackingStage.submitted,
            RequestTrackingStage.approved,
            RequestTrackingStage.driverAssigned,
            RequestTrackingStage.inProgress,
            RequestTrackingStage.finished,
            RequestTrackingStage.awaitingConfirmation,
          ])
            RequestTrackingEvent(
              stage: step,
              actorRole: UserRole.employee,
              reachedAt: reached.contains(step) ? submittedAt : null,
            ),
        ],
  );
}
