import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_logo.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/auth_gradient_header.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';

/// Auth shell: gradient header, hero logo, overlapping white card.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.showSignOut = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// When true, shows a compact sign-out control beside the language toggle.
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppAnimations.disabled(context);

    return AppScaffold(
      showAppBar: false,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AuthGradientHeader(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const LanguageToggleButton(
                                onBrandBackground: true,
                              ),
                              if (showSignOut)
                                const SignOutButton(
                                  style: SignOutButtonStyle.icon,
                                  onBrandBackground: true,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HeroLogo(reduceMotion: reduceMotion),
                        const SizedBox(height: 20),
                        _AuthCard(
                          title: title,
                          subtitle: subtitle,
                          reduceMotion: reduceMotion,
                          child: child,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 28,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const AppLogo(height: 90, heroTag: AppLogo.defaultHeroTag),
    );

    if (reduceMotion) return logo;

    return logo
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.08, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.child,
    required this.reduceMotion,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget card = Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      shadowColor: AppColors.deepBlue.withValues(alpha: 0.16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsetsDirectional.fromSTEB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlue.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.navy.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

/// Staggers form children for auth screens.
class AuthStagger extends StatelessWidget {
  const AuthStagger({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.disabled(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 60 * i),
                duration: 320.ms,
              )
              .slideY(
                begin: 0.06,
                end: 0,
                delay: Duration(milliseconds: 60 * i),
                duration: 320.ms,
                curve: Curves.easeOutCubic,
              ),
      ],
    );
  }
}

/// Compact progress indicator for multi-section signup.
class AuthSectionProgress extends StatelessWidget {
  const AuthSectionProgress({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppAnimations.duration(
                context,
                const Duration(milliseconds: 250),
              ),
              height: 4,
              decoration: BoxDecoration(
                color: i <= currentStep
                    ? AppColors.deepBlue
                    : AppColors.paleBlue,
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
            ),
          ),
          if (i < totalSteps - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
