import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/navigation/nav_ids.dart';
import 'package:teletech_drivers/core/navigation/nav_item.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';
import 'package:teletech_drivers/core/presentation/glass_bottom_bar.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';

const _items = [
  NavItem(
    id: NavIds.trips,
    icon: Icons.directions_car_outlined,
    labelKey: NavLabelKey.trips,
    route: '/driver',
  ),
  NavItem(
    id: NavIds.profile,
    icon: Icons.person_outline,
    labelKey: NavLabelKey.profile,
    route: '/driver/profile',
  ),
];

const _more = [
  NavItem(
    id: NavIds.settings,
    icon: Icons.settings_outlined,
    labelKey: NavLabelKey.settings,
    route: '/driver/settings',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBar(
    WidgetTester tester, {
    int selectedIndex = 0,
    bool moreSelected = false,
    ValueChanged<int>? onSelected,
    ValueChanged<NavItem>? onMoreSelected,
    Locale locale = const Locale('en'),
    MediaQueryData? mediaQuery,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final bar = GlassBottomBar(
      items: _items,
      moreItems: _more,
      selectedIndex: selectedIndex,
      moreSelected: moreSelected,
      onSelected: onSelected ?? (_) {},
      onMoreSelected: onMoreSelected,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: mediaQuery == null
              ? Align(alignment: Alignment.bottomCenter, child: bar)
              : MediaQuery(
                  data: mediaQuery,
                  child: Align(alignment: Alignment.bottomCenter, child: bar),
                ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders items and the selected highlight', (tester) async {
    await pumpBar(tester);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    final trips = tester.getSemantics(find.text('Trips')).getSemanticsData();
    expect(trips.label, 'Trips');
    expect(trips.flagsCollection.isButton, isTrue);
    expect(trips.flagsCollection.isSelected.name, 'isTrue');
    final profile = tester.getSemantics(find.text('Profile')).getSemanticsData();
    expect(profile.label, 'Profile');
    expect(profile.flagsCollection.isSelected.name, 'isFalse');
  });

  testWidgets('onTap reports the item index', (tester) async {
    int? tapped;
    await pumpBar(tester, onSelected: (index) => tapped = index);
    await tester.tap(find.text('Profile'));
    expect(tapped, 1);
  });

  testWidgets('More opens the sheet and highlights when a destination is active', (
    tester,
  ) async {
    NavItem? chosen;
    await pumpBar(
      tester,
      selectedIndex: -1,
      moreSelected: true,
      onMoreSelected: (item) => chosen = item,
    );
    final more = tester.getSemantics(find.text('More')).getSemanticsData();
    expect(more.label, 'More');
    expect(more.flagsCollection.isSelected.name, 'isTrue');

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(chosen?.id, NavIds.settings);
  });

  testWidgets('lays out in RTL and at text scale 2 without overflow', (tester) async {
    await pumpBar(
      tester,
      locale: const Locale('ar'),
      size: const Size(320, 700),
      mediaQuery: const MediaQueryData(
        size: Size(320, 700),
        textScaler: TextScaler.linear(2),
      ),
    );
    expect(find.text('الرحلات'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.text('الرحلات'))),
      TextDirection.rtl,
    );
  });

  testWidgets('hides while the keyboard is visible', (tester) async {
    await pumpBar(
      tester,
      mediaQuery: const MediaQueryData(
        viewInsets: EdgeInsets.only(bottom: 280),
      ),
    );
    expect(find.byKey(GlassBottomBar.barKey), findsNothing);
    expect(find.text('Trips'), findsNothing);
  });
}
