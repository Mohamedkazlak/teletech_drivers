import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/time/cairo_clock.dart';
import 'package:teletech_drivers/features/trip_request/presentation/scheduling/future_schedule.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/future_schedule_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openPicker(
    WidgetTester tester, {
    required DateTime Function() now,
    required ValueChanged<DateTime> onConfirm,
    String? errorText,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final picked = await FutureScheduleDialog.pick(
                    context,
                    now: now,
                    errorText: errorText,
                  );
                  if (picked != null) onConfirm(picked);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> acceptDate(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  InkWell periodButton(WidgetTester tester, String key) {
    return tester.widget<InkWell>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(InkWell)),
    );
  }

  testWidgets('hides earlier hours today and defaults to the next minute', (
    tester,
  ) async {
    final cairoNow = DateTime(2026, 11, 16, 14, 0, 30);
    DateTime? picked;
    await openPicker(
      tester,
      now: () => cairoNow,
      onConfirm: (value) => picked = value,
    );

    final schedule = FutureSchedule(now: () => cairoNow);
    expect(schedule.isDaySelectable(DateTime(2026, 11, 15)), isFalse);
    expect(schedule.isDaySelectable(DateTime(2026, 11, 16)), isTrue);
    expect(schedule.nextSlot(), DateTime(2026, 11, 16, 14, 1));
    expect(find.text('Mon, Nov 16'), findsOneWidget);
    expect(find.text('Nov 15, 2026'), findsNothing);

    await acceptDate(tester);

    for (var hour = 0; hour < 14; hour++) {
      expect(find.byKey(ValueKey('schedule-hour-$hour')), findsNothing);
    }
    expect(find.byKey(const ValueKey('schedule-hour-14')), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(periodButton(tester, 'schedule-period-am').onTap, isNull);
    expect(periodButton(tester, 'schedule-period-pm').onTap, isNotNull);
    expect(find.text('01'), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-minute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-minute-0')), findsNothing);
    expect(find.byKey(const ValueKey('schedule-minute-5')), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-confirm')));
    await tester.pumpAndSettle();
    expect(picked, CairoClock.toUtc(DateTime(2026, 11, 16, 14, 1)));
    expect(picked!.isAfter(CairoClock.toUtc(cairoNow)), isTrue);
  });

  testWidgets('moves to tomorrow when today has no future minute', (
    tester,
  ) async {
    final cairoNow = DateTime(2026, 11, 16, 23, 59, 10);
    await openPicker(tester, now: () => cairoNow, onConfirm: (_) {});

    final schedule = FutureSchedule(now: () => cairoNow);
    expect(schedule.earliestDay(), DateTime(2026, 11, 17));
    expect(
      schedule.isMinuteSelectable(DateTime(2026, 11, 16), 23, 59),
      isFalse,
    );
    expect(find.text('Tue, Nov 17'), findsOneWidget);
    expect(find.text('Nov 16, 2026'), findsNothing);

    await acceptDate(tester);

    expect(find.byKey(const ValueKey('schedule-hour-0')), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('00'), findsWidgets);
  });

  testWidgets('shows the server message on the schedule field', (tester) async {
    await openPicker(
      tester,
      now: () => DateTime(2026, 11, 16, 14),
      onConfirm: (_) {},
      errorText: 'The scheduled time must be in the future.',
    );

    expect(
      find.text('The scheduled time must be in the future.'),
      findsOneWidget,
    );
  });
}
