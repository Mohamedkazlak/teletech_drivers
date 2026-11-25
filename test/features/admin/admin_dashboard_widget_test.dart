import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/user_account_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_private_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final admin = AppUser(
    id: 'admin-1',
    name: 'System Admin',
    email: 'admin@test.com',
    role: UserRole.admin,
    phone: '01000000000',
    branch: Branch.companyHeadquarters,
  );

  final driver = DriverProfile(
    id: 'd1',
    nameEn: 'Driver',
    nameAr: 'سائق',
    email: 'd@test.com',
    phone: '01011111111',
    isActive: true,
    privateProfile: const DriverPrivateProfile(
      nationalId: '12345678901234',
      carLicense: 'CAR',
      personalLicense: 'PER',
    ),
  );

  final place = Place(
    id: 'p1',
    nameEn: 'HQ',
    nameAr: 'المقر',
    isActive: true,
    createdAt: DateTime(2026),
  );

  final employee = AppUser(
    id: 'e1',
    name: 'Emp',
    email: 'e@test.com',
    role: UserRole.employee,
    phone: '01022222222',
    branch: Branch.newHeadquarters,
  );

  final myRequest = TripRequest(
    id: 'r1',
    employeeId: admin.id,
    employeeName: admin.name,
    employeeBranch: Branch.companyHeadquarters,
    employeePhone: admin.phone!,
    pickupPlaceName: 'HQ',
    destinationPlaceName: 'Villa',
    requestedDateTime: DateTime(2026, 11, 2, 9),
    notes: '',
    status: TripRequestStatus.approved,
    createdAt: DateTime(2026, 11, 1),
    autoApproved: true,
    requesterRole: UserRole.admin.name,
  );

  testWidgets('admin dashboard shows only permitted sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(admin)),
          allDriverProfilesProvider.overrideWith(
            (ref) => Stream.value(<DriverProfile>[driver]),
          ),
          allPlacesProvider.overrideWith((ref) => Stream.value(<Place>[place])),
          allEmployeesProvider.overrideWith(
            (ref) => Stream.value(<AppUser>[employee]),
          ),
          allUserAccountsProvider.overrideWith(
            (ref) => Stream.value(<AppUser>[admin, employee]),
          ),
          employeeTripRequestsProvider.overrideWith(
            (ref) => Stream.value(<TripRequest>[myRequest]),
          ),
          allTripsProvider.overrideWith((ref) => Stream.value(<Trip>[])),
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
          home: const AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.adminDriversSection), findsOneWidget);
    expect(find.text(l10n.adminPlacesSection), findsOneWidget);
    expect(find.text(l10n.adminEmployeesSection), findsOneWidget);
    expect(find.text(l10n.adminUsersSection), findsOneWidget);
    expect(find.text(l10n.adminMyTripsSection), findsOneWidget);
    expect(find.text(l10n.adminRequestTripSection), findsOneWidget);

    // Forbidden capabilities must not appear on the dashboard.
    expect(find.text(l10n.requestsTab), findsNothing);
    expect(find.text(l10n.tripsTab), findsNothing);
    expect(find.textContaining('Live'), findsNothing);
    expect(find.textContaining('Assign'), findsNothing);
  });
}
