import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/admin/domain/repositories/user_account_repository.dart';
import 'package:teletech_drivers/features/admin/data/providers/user_account_repository_provider.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final admin = AppUser(
    id: 'admin-1',
    name: 'System Admin',
    email: 'admin@test.com',
    role: UserRole.admin,
  );
  final employee = AppUser(
    id: 'emp-1',
    name: 'Sara Nabil',
    email: 'sara@test.com',
    role: UserRole.employee,
    phone: '01000000000',
  );

  testWidgets('admin resets another user and cannot reset themselves', (
    tester,
  ) async {
    final repository = _FakeUserAccountRepository([admin, employee]);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(admin)),
          userAccountRepositoryProvider.overrideWith((ref) => repository),
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
          home: const AdminUsersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Admin'), findsOneWidget);
    expect(find.text('Sara Nabil'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.adminResetPasswordAction));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.adminResetPasswordMessage('Sara Nabil')),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.temporaryPasswordLabel),
      'temporary1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.confirmPasswordLabel),
      'temporary1',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.adminResetPasswordAction),
    );
    await tester.pumpAndSettle();

    expect(repository.resetUserId, 'emp-1');
    expect(repository.resetPasswordValue, 'temporary1');
    expect(find.text(l10n.adminResetPasswordSuccess), findsOneWidget);
    // Let the success moment dismiss itself.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}

class _FakeUserAccountRepository implements UserAccountRepository {
  _FakeUserAccountRepository(this.users);

  final List<AppUser> users;
  String? resetUserId;
  String? resetPasswordValue;

  @override
  Future<void> resetPassword({
    required String userId,
    required String password,
  }) async {
    resetUserId = userId;
    resetPasswordValue = password;
  }

  @override
  Stream<List<AppUser>> watchAllUsers() => Stream.value(users);
}
