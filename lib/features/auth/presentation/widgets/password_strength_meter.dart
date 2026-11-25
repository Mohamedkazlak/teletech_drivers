import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Four bars that fill as the password gets stronger, with a word label.
///
/// Guidance only; [AuthValidators.password] still decides what's accepted.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  /// 0 (empty) to 4 (strong).
  static int score(String value) {
    if (value.isEmpty) return 0;
    var points = 0;
    if (value.length >= 8) points++;
    if (value.length >= 12) points++;
    if (RegExp('[a-z]').hasMatch(value) && RegExp('[A-Z]').hasMatch(value)) {
      points++;
    }
    if (RegExp(r'\d').hasMatch(value)) points++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) points++;
    if (value.length < 8) return 1;
    return points.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = score(password);
    final duration = AppAnimations.duration(context, AppMotion.standard);
    final (label, color) = switch (value) {
      1 => (l10n.passwordStrengthWeak, AppColors.error),
      2 => (l10n.passwordStrengthFair, AppColors.warning),
      3 => (l10n.passwordStrengthGood, AppColors.signal),
      _ => (l10n.passwordStrengthStrong, AppColors.success),
    };

    return AnimatedSize(
      duration: duration,
      curve: AppMotion.easeOut,
      alignment: AlignmentDirectional.topStart,
      child: value == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: 10, start: 4),
              child: Semantics(
                label: label,
                excludeSemantics: true,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: duration,
                          curve: AppMotion.easeOut,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < value ? color : AppColors.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: duration,
                      child: Text(
                        label,
                        key: ValueKey(label),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.inkOn(color),
                              fontWeight: FontWeight.w600,
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
