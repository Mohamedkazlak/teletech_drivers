import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/role_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/home_header.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/attendance/presentation/widgets/driver_attendance_section.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_tracking_banner.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/resume_tracking_controller.dart';

/// Driver attendance: today's status, QR scan, and history.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(currentUserProvider);
    ref.watch(resumeTrackingProvider);

    return AppScaffold(
      title: l10n.navAttendance,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      body: SafeArea(
        child: auth.when(
          loading: () =>
              Center(child: AppLoadingIndicator(label: l10n.loading)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                messageForError(error, l10n),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  l10n.homeEmpty,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView(
              padding: GlassBarInset.listPadding(
                context,
                const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
              ),
              children: [
                _DriverHomeHeader(user: user),
                const DriverTrackingBanner(),
                const DriverAttendanceSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverHomeHeader extends StatelessWidget {
  const _DriverHomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final chips = <Widget>[
      HomeHeaderChip(label: roleLabel(user.role, l10n)),
      if (user.branch != null)
        HomeHeaderChip(label: branchLabel(user.branch!, l10n)),
    ];

    return HomeHeader(
      greeting: l10n.roleHomeWelcome(user.localizedName(languageCode)),
      chips: chips,
    );
  }
}
