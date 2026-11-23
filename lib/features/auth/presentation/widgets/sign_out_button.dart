import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/logout_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/logout_confirmation.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// How [SignOutButton] renders in the chrome vs. form bodies.
enum SignOutButtonStyle {
  /// Full-width outlined control (splash / form fallback).
  outlined,

  /// Compact app-bar control beside the language toggle.
  icon,
}

class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({
    this.style = SignOutButtonStyle.outlined,
    this.onBrandBackground = false,
    super.key,
  });

  final SignOutButtonStyle style;

  /// White chrome when placed on the blue auth header.
  final bool onBrandBackground;

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSigningOut = ref.watch(logoutControllerProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user?.role == UserRole.driver) {
      ref.watch(driverTripsProvider(user!.id));
    }

    return switch (widget.style) {
      SignOutButtonStyle.icon => _IconSignOut(
        label: l10n.signOut,
        loadingLabel: l10n.loading,
        isSigningOut: isSigningOut,
        onBrandBackground: widget.onBrandBackground,
        onPressed: isSigningOut
            ? null
            : () => confirmAndSignOut(ref, context),
      ),
      SignOutButtonStyle.outlined => OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: isSigningOut
            ? null
            : () => confirmAndSignOut(ref, context),
        child: isSigningOut
            ? SizedBox.square(
                dimension: 22,
                child: Semantics(
                  label: l10n.loading,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Text(l10n.signOut),
      ),
    };
  }
}

class _IconSignOut extends StatelessWidget {
  const _IconSignOut({
    required this.label,
    required this.loadingLabel,
    required this.isSigningOut,
    required this.onBrandBackground,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool isSigningOut;
  final bool onBrandBackground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onBrandBackground ? AppColors.white : null;

    if (isSigningOut) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        child: SizedBox.square(
          dimension: 22,
          child: Semantics(
            label: loadingLabel,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: color,
      icon: const Icon(Icons.logout),
    );
  }
}
