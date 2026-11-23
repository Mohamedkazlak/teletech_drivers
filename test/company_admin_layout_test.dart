import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_home_screen.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final request = TripRequest(
    id: 'r1',
    employeeId: 'e1',
    employeeName: 'Ada Lovelace',
    employeeBranch: Branch.companyHeadquarters,
    employeePhone: '01000000000',
    pickupPlaceName: 'HQ',
    destinationPlaceName: 'Villa',
    requestedDateTime: DateTime(2026, 10, 18, 9),
    notes: 'Client visit',
    status: TripRequestStatus.pending,
    createdAt: DateTime(2026, 10, 17),
  );

  final place = Place(
    id: 'p1',
    nameEn: 'Headquarters',
    nameAr: 'المقر',
    isActive: true,
    createdAt: DateTime(2026),
  );

  Future<void> pumpHome(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 640),
    List<TripRequest>? requests,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTripRequestsProvider.overrideWith(
            (ref, query) => Stream.value(requests ?? <TripRequest>[request]),
          ),
          allTripRequestsProvider.overrideWith(
            (ref) => Stream.value(requests ?? <TripRequest>[request]),
          ),
          employeeTripRequestsProvider.overrideWith(
            (ref) => Stream.value(<TripRequest>[]),
          ),
          allTripsProvider.overrideWith((ref) => Stream.value(<Trip>[])),
          allDriversProvider.overrideWith((ref) => Stream.value(<AppUser>[])),
          allPlacesProvider.overrideWith((ref) => Stream.value(<Place>[place])),
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
          home: const CompanyAdminHomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('company admin home with data', (tester) async {
    await _captureErrors(tester, () async {
      await pumpHome(tester);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });
  });

  testWidgets('company admin home stays one column on a wide window', (
    tester,
  ) async {
    final second = TripRequest(
      id: 'r2',
      employeeId: 'e2',
      employeeName: 'Grace Hopper',
      employeeBranch: Branch.companyHeadquarters,
      employeePhone: '01000000001',
      pickupPlaceName: 'HQ',
      destinationPlaceName: 'Plant',
      requestedDateTime: DateTime(2026, 10, 18, 11),
      notes: 'Site visit',
      status: TripRequestStatus.pending,
      createdAt: DateTime(2026, 10, 17),
    );

    await _captureErrors(tester, () async {
      await pumpHome(
        tester,
        size: const Size(1400, 1600),
        requests: [request, second],
      );
      final firstTop = tester.getTopLeft(find.text('Ada Lovelace'));
      final secondTop = tester.getTopLeft(find.text('Grace Hopper'));
      expect(secondTop.dy, greaterThan(firstTop.dy));
      expect(secondTop.dx, firstTop.dx);
    });
  });

  testWidgets('company admin home arabic narrow', (tester) async {
    await _captureErrors(tester, () async {
      await pumpHome(
        tester,
        locale: const Locale('ar'),
        size: const Size(320, 480),
      );
    });
  });

  testWidgets('auth scaffold with keyboard inset', (tester) async {
    await _captureErrors(tester, () async {
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
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
            home: const MediaQuery(
              data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 320)),
              child: AuthPageScaffold(
                title: 'Sign in',
                subtitle: 'Sign in with your company account.',
                child: SizedBox(height: 240),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });
}

Future<void> _captureErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };
  final previousException = tester.binding.platformDispatcher.onError;
  Object? thrown;
  try {
    await body();
  } catch (error) {
    thrown = error;
  }
  FlutterError.onError = previous;
  tester.binding.platformDispatcher.onError = previousException;
  if (thrown != null || errors.isNotEmpty) {
    fail(
      [
        if (thrown != null) thrown.toString(),
        ...errors.map((e) => e.exceptionAsString()),
      ].join('\n---\n'),
    );
  }
}
