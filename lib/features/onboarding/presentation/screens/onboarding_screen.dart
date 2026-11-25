import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/router/role_route_strategy.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:teletech_drivers/features/onboarding/presentation/widgets/onboarding_art.dart';

class _Step {
  const _Step({
    required this.icon,
    required this.satellites,
    required this.title,
    required this.body,
    this.brand = false,
  });

  final IconData icon;
  final List<IconData> satellites;
  final String title;
  final String body;
  final bool brand;
}

List<_Step> _stepsFor(UserRole role, AppLocalizations l) {
  final role3 = switch (role) {
    UserRole.employee => [
      _Step(
        icon: Icons.add_road,
        satellites: const [
          Icons.place_outlined,
          Icons.schedule,
          Icons.directions_car_outlined,
        ],
        title: l.onboardingEmployee1Title,
        body: l.onboardingEmployee1Body,
      ),
      _Step(
        icon: Icons.map_outlined,
        satellites: const [
          Icons.directions_car_outlined,
          Icons.near_me_outlined,
          Icons.notifications_none,
        ],
        title: l.onboardingEmployee2Title,
        body: l.onboardingEmployee2Body,
      ),
      _Step(
        icon: Icons.dashboard_outlined,
        satellites: const [
          Icons.history,
          Icons.notifications_none,
          Icons.translate,
        ],
        title: l.onboardingEmployee3Title,
        body: l.onboardingEmployee3Body,
      ),
    ],
    UserRole.driver => [
      _Step(
        icon: Icons.how_to_reg_outlined,
        satellites: const [
          Icons.access_time,
          Icons.swipe_right_alt,
          Icons.verified_outlined,
        ],
        title: l.onboardingDriver1Title,
        body: l.onboardingDriver1Body,
      ),
      _Step(
        icon: Icons.route_outlined,
        satellites: const [
          Icons.play_arrow_rounded,
          Icons.flag_outlined,
          Icons.my_location,
        ],
        title: l.onboardingDriver2Title,
        body: l.onboardingDriver2Body,
      ),
      _Step(
        icon: Icons.insights_outlined,
        satellites: const [
          Icons.check_circle_outline,
          Icons.speed,
          Icons.calendar_today_outlined,
        ],
        title: l.onboardingDriver3Title,
        body: l.onboardingDriver3Body,
      ),
    ],
    UserRole.companyAdmin => [
      _Step(
        icon: Icons.fact_check_outlined,
        satellites: const [
          Icons.check,
          Icons.close,
          Icons.group_work_outlined,
        ],
        title: l.onboardingCompanyAdmin1Title,
        body: l.onboardingCompanyAdmin1Body,
      ),
      _Step(
        icon: Icons.add_location_alt_outlined,
        satellites: const [
          Icons.place_outlined,
          Icons.search,
          Icons.map_outlined,
        ],
        title: l.onboardingCompanyAdmin2Title,
        body: l.onboardingCompanyAdmin2Body,
      ),
      _Step(
        icon: Icons.timeline,
        satellites: const [
          Icons.directions_car_outlined,
          Icons.add,
          Icons.flag_outlined,
        ],
        title: l.onboardingCompanyAdmin3Title,
        body: l.onboardingCompanyAdmin3Body,
      ),
    ],
    UserRole.driversAdmin => [
      _Step(
        icon: Icons.assignment_ind_outlined,
        satellites: const [
          Icons.person_outline,
          Icons.directions_car_outlined,
          Icons.touch_app_outlined,
        ],
        title: l.onboardingDriversAdmin1Title,
        body: l.onboardingDriversAdmin1Body,
      ),
      _Step(
        icon: Icons.map_outlined,
        satellites: const [
          Icons.near_me_outlined,
          Icons.directions_car_outlined,
          Icons.radio_button_checked,
        ],
        title: l.onboardingDriversAdmin2Title,
        body: l.onboardingDriversAdmin2Body,
      ),
      _Step(
        icon: Icons.event_available_outlined,
        satellites: const [
          Icons.qr_code_2,
          Icons.edit_calendar_outlined,
          Icons.file_download_outlined,
        ],
        title: l.onboardingDriversAdmin3Title,
        body: l.onboardingDriversAdmin3Body,
      ),
    ],
    UserRole.admin => [
      _Step(
        icon: Icons.dashboard_outlined,
        satellites: const [
          Icons.bar_chart,
          Icons.people_outline,
          Icons.directions_car_outlined,
        ],
        title: l.onboardingAdmin1Title,
        body: l.onboardingAdmin1Body,
      ),
      _Step(
        icon: Icons.groups_outlined,
        satellites: const [
          Icons.person_add_alt_1,
          Icons.place_outlined,
          Icons.badge_outlined,
        ],
        title: l.onboardingAdmin2Title,
        body: l.onboardingAdmin2Body,
      ),
      _Step(
        icon: Icons.admin_panel_settings_outlined,
        satellites: const [Icons.lock_reset, Icons.history, Icons.tune],
        title: l.onboardingAdmin3Title,
        body: l.onboardingAdmin3Body,
      ),
    ],
  };
  return [
    _Step(
      icon: Icons.waving_hand_outlined,
      satellites: const [
        Icons.directions_car_outlined,
        Icons.place_outlined,
        Icons.notifications_none,
      ],
      title: l.onboardingWelcomeTitle,
      body: l.onboardingWelcomeBody,
      brand: true,
    ),
    ...role3,
    _Step(
      icon: Icons.check_rounded,
      satellites: const [
        Icons.celebration_outlined,
        Icons.thumb_up_alt_outlined,
        Icons.rocket_launch_outlined,
      ],
      title: l.onboardingDoneTitle,
      body: l.onboardingDoneBody,
    ),
  ];
}

/// First-run guide: swipeable, role-specific, animated. Shown once after a
/// new user finishes setup; Settings can replay it.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;
  var _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final role = ref.read(currentUserProvider).value?.role;
    await completeOnboarding(ref);
    if (!mounted) return;
    if (role == null) return;
    context.go(const AppRoleRouteStrategy().homeLocation(role));
  }

  void _next(int count) {
    if (_index >= count - 1) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      duration: AppAnimations.duration(context, AppMotion.emphasized),
      curve: AppMotion.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).value;
    final role = user?.role ?? UserRole.employee;
    final steps = _stepsFor(role, l10n);
    final last = _index == steps.length - 1;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _StepPage(
                  step: steps[i],
                  index: i,
                  active: i == _index,
                  pageController: _controller,
                  greetingName: i == 0 ? user?.name : null,
                  bottomReserve: 150 + MediaQuery.paddingOf(context).bottom,
                  compact: size.height < 640,
                ),
              ),
              PositionedDirectional(
                top: 8,
                start: 16,
                child: Row(
                  children: [
                    const BrandMark(size: 26, color: AppColors.signal),
                    const SizedBox(width: 8),
                    Text(
                      'TeleCars',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PositionedDirectional(
                top: 4,
                end: 8,
                child: LanguageToggleButton(onBrandBackground: true),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  color: AppColors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dots(count: steps.length, index: _index),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AnimatedSize(
                            duration: AppAnimations.duration(
                              context,
                              AppMotion.standard,
                            ),
                            curve: AppMotion.easeOut,
                            child: last
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 12,
                                    ),
                                    child: TextButton(
                                      onPressed: _finishing ? null : _finish,
                                      child: Text(l10n.onboardingSkip),
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: AppButton(
                              label: last
                                  ? l10n.onboardingGetStarted
                                  : l10n.onboardingNext,
                              pulse: last,
                              isLoading: _finishing,
                              trailingIcon: last
                                  ? null
                                  : (rtl
                                        ? Icons.arrow_back_rounded
                                        : Icons.arrow_forward_rounded),
                              icon: last ? Icons.check_rounded : null,
                              onPressed: () => _next(steps.length),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatefulWidget {
  const _StepPage({
    required this.step,
    required this.index,
    required this.active,
    required this.pageController,
    required this.bottomReserve,
    required this.compact,
    this.greetingName,
  });

  final _Step step;
  final int index;
  final bool active;
  final PageController pageController;
  final double bottomReserve;
  final bool compact;
  final String? greetingName;

  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _text.forward();
  }

  @override
  void didUpdateWidget(_StepPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (AppAnimations.disabled(context)) {
        _text.value = 1;
      } else {
        _text.forward(from: 0);
      }
    } else if (!widget.active && oldWidget.active) {
      _text.value = 0;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Widget _reveal(double from, double to, Widget child) {
    final curve = CurvedAnimation(
      parent: _text,
      curve: Interval(from, to, curve: AppMotion.easeOut),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = widget.step;
    final name = widget.greetingName;
    return Column(
      children: [
        Expanded(
          flex: widget.compact ? 4 : 5,
          child: AnimatedBuilder(
            animation: widget.pageController,
            builder: (context, child) {
              var offset = 0.0;
              if (widget.pageController.hasClients &&
                  widget.pageController.position.haveDimensions) {
                offset = (widget.pageController.page ?? 0) - widget.index;
              }
              // The art drifts and fades a little against the swipe.
              return Opacity(
                opacity: (1 - offset.abs() * 0.8).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(offset * 70, 0),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 8),
              child: Center(
                child: OnboardingArt(
                  icon: step.icon,
                  satellites: step.satellites,
                  active: widget.active,
                  useBrandMark: step.brand,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(28, 32, 28, widget.bottomReserve - 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null && name.isNotEmpty)
                    _reveal(
                      0,
                      0.5,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.signal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  _reveal(
                    0.05,
                    0.6,
                    Text(
                      step.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reveal(
                    0.25,
                    0.85,
                    Text(
                      step.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final duration = AppAnimations.duration(context, AppMotion.standard);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: duration,
            curve: AppMotion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 8,
            width: i == index ? 28 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == index ? AppColors.deepBlue : AppColors.line,
            ),
          ),
      ],
    );
  }
}
