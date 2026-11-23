import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_trip_list_tile.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/utils/localized_place_name.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_requester.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_requesters_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dialer = MethodChannel('com.teletech.teletech_drivers/dialer');
  final dialed = <String>[];

  setUp(() {
    dialed.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dialer, (call) async {
          dialed.add(call.arguments as String);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dialer, null);
  });

  testWidgets('assigned trip card shows the requester, phone, and count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        child: DriverTripListTile(trip: _trip(), showActions: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requester'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('Passengers: 2'), findsOneWidget);
    expect(find.text('Omar Fathy'), findsNothing);

    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.pump();
    expect(dialed, ['01012345678']);
  });

  testWidgets('Arabic locale uses the Arabic requester name', (tester) async {
    await tester.pumpWidget(
      _app(
        locale: const Locale('ar'),
        child: TripRequestersSection(
          requesters: _trip().requesters,
          passengerCount: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مقدّم الطلب'), findsOneWidget);
    expect(find.text('سارة علي'), findsOneWidget);
    expect(find.text('Sara Ali'), findsNothing);
    expect(find.text('الركاب: 2'), findsOneWidget);
  });

  testWidgets('grouped trip lists every requester and the server total', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        child: TripRequestersSection(
          requesters: const [
            TripRequester(
              id: 'emp-1',
              nameEn: 'Sara Ali',
              nameAr: 'سارة علي',
              phone: '01011110001',
              branch: Branch.companyHeadquarters,
            ),
            TripRequester(
              id: 'emp-2',
              nameEn: 'Omar Fathy',
              nameAr: 'عمر فتحي',
              phone: '01011110002',
              branch: Branch.newHeadquarters,
            ),
          ],
          passengerCount: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requesters'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('Omar Fathy'), findsOneWidget);
    expect(find.text('01011110001'), findsOneWidget);
    expect(find.text('01011110002'), findsOneWidget);
    expect(find.text('Passengers: 2'), findsOneWidget);
    expect(find.text('secret@example.com'), findsNothing);
  });
}

Widget _app({required Locale locale, required Widget child}) {
  return ProviderScope(
    overrides: [
      placeNameResolverProvider.overrideWithValue(PlaceNameResolver(const [])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: locale,
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

Trip _trip() {
  return Trip(
    id: 'trip-1',
    requestIds: const ['req-1'],
    passengerIds: const ['emp-1'],
    passengerNames: const ['Sara Ali'],
    passengerBranches: const [Branch.companyHeadquarters],
    pickupSummary: 'HQ',
    destinationSummary: 'Site',
    scheduledAt: DateTime.utc(2026, 11, 11, 9),
    status: TripStatus.assigned,
    createdBy: 'dispatcher',
    createdAt: DateTime.utc(2026, 11, 1),
    requesters: const [
      TripRequester(
        id: 'emp-1',
        nameEn: 'Sara Ali',
        nameAr: 'سارة علي',
        phone: '01012345678',
        branch: Branch.companyHeadquarters,
      ),
    ],
    passengerCount: 2,
  );
}
