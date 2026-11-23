import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/attendance/presentation/utils/attendance_error_message.dart';

void main() {
  testWidgets('maps attendance error codes in English and Arabic', (
    tester,
  ) async {
    late AppLocalizations english;
    late AppLocalizations arabic;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            english = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            arabic = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      attendanceErrorMessage(english, code: 'invalid_qr'),
      'This QR code is not valid.',
    );
    expect(
      attendanceErrorMessage(english, code: 'mock_location'),
      contains('mocked'),
    );
    expect(
      attendanceErrorMessage(english, code: 'active_trip'),
      contains('active trip'),
    );
    expect(
      attendanceErrorMessage(
        english,
        code: 'outside_radius',
        distanceM: 180,
        radiusM: 150,
      ),
      'You are 180 m from headquarters. The allowed radius is 150 m.',
    );
    expect(
      attendanceErrorMessage(
        arabic,
        code: 'outside_radius',
        distanceM: 180,
        radiusM: 150,
      ),
      contains('180'),
    );
    expect(
      attendanceErrorMessage(arabic, code: 'already_checked_in'),
      contains('حضور'),
    );
  });
}
