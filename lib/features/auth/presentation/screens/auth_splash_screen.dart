import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_logo.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';

/// Shown while auth state is resolving, and when that resolution fails.
class AuthSplashScreen extends ConsumerWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(currentUserProvider);
    final reduceMotion = AppAnimations.disabled(context);

    return AppScaffold(
      showAppBar: false,
      backgroundColor: AppColors.deepBlue,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Stack(
            children: [
              const Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 4, end: 8),
                  child: LanguageToggleButton(),
                ),
              ),
              auth.when(
                loading: () => _SplashLogo(reduceMotion: reduceMotion),
                data: (_) => _SplashLogo(reduceMotion: reduceMotion),
                error: (error, _) =>
                    _AuthSplashError(message: messageForError(error, l10n)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      padding: const EdgeInsetsDirectional.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const AppLogo(height: 96, heroTag: AppLogo.defaultHeroTag),
    );

    if (!reduceMotion) {
      logo = logo
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          )
          .shimmer(delay: 200.ms, duration: 900.ms);
    }

    return Center(child: logo);
  }
}

class _AuthSplashError extends ConsumerWidget {
  const _AuthSplashError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.couldNotContinue,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.tryAgain,
            onPressed: () => ref.invalidate(currentUserProvider),
          ),
          const SizedBox(height: 8),
          const SignOutButton(),
        ],
      ),
    );
  }
}
