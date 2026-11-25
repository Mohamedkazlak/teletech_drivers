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

    void toggle() {
      // Drop focus before rebuilding localizations so the soft keyboard
      // reconnects cleanly on the next field tap.
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(localeControllerProvider.notifier).toggleEnglishArabic();
    }

    if (!onBrandBackground) {
      // App bars: a compact "ع" / "EN" pill so screen titles keep their
      // room. The full language name stays in the tooltip and semantics.
      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: InkWell(
              onTap: toggle,
              customBorder: const StadiumBorder(),
              child: Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 34),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(color: AppColors.line),
                  ),
                ),
                child: Text(
                  isArabic ? 'EN' : 'ع',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.deepBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

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
      onPressed: toggle,
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
