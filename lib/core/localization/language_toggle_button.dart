import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Switches the session language between English and Arabic.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({this.onBrandBackground = false, super.key});

  /// White pill for the blue auth header. App bars keep the default text button.
  final bool onBrandBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isArabic = ref.watch(localeControllerProvider).languageCode == 'ar';
    final label = isArabic ? l10n.languageEnglish : l10n.languageArabic;

    return TextButton(
      style: onBrandBackground
          ? TextButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.white.withValues(alpha: 0.18),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.white),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      onPressed: () {
        // Drop focus before rebuilding localizations so the soft keyboard
        // reconnects cleanly on the next field tap.
        FocusManager.instance.primaryFocus?.unfocus();
        ref.read(localeControllerProvider.notifier).toggleEnglishArabic();
      },
      child: onBrandBackground
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 18),
                const SizedBox(width: 6),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}
