import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/shake.dart';

/// Opens a create/edit form as a tall bottom sheet.
///
/// Long forms get the whole screen width, the keyboard pushes the content up,
/// and the main action stays pinned at the bottom.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.scaffold,
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      curve: AppMotion.drawer,
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 260),
    ),
    builder: builder,
  );
}

/// Layout for a form shown with [showFormSheet]: header, scrolling sections,
/// pinned cancel + primary buttons.
class FormSheet extends StatelessWidget {
  const FormSheet({
    required this.title,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.formKey,
    this.subtitle,
    this.icon,
    this.isLoading = false,
    this.errorMessage,
    this.shakeTrigger = 0,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final GlobalKey<FormState>? formKey;

  /// Usually [FormSection]s.
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final String? errorMessage;

  /// Change this value to shake the form (e.g. after a failed validation).
  final int shakeTrigger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final animate = !AppAnimations.disabled(context);

    Widget body = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        AnimatedErrorBanner(message: errorMessage),
        if (errorMessage != null) const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          animate
              ? children[i]
                    .animate()
                    .fadeIn(
                      delay: 80.ms + AppMotion.staggerAt(i),
                      duration: AppMotion.standard,
                    )
                    .moveY(
                      begin: 10,
                      end: 0,
                      delay: 80.ms + AppMotion.staggerAt(i),
                      duration: AppMotion.emphasized,
                      curve: AppMotion.easeOut,
                    )
              : children[i],
        ],
      ],
    );
    if (formKey != null) body = Form(key: formKey, child: body);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.paleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.deepBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: textTheme.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.dialogCancel,
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Shake(trigger: shakeTrigger, child: body),
            ),
            FormActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.dialogCancel,
                      variant: AppButtonVariant.outlined,
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: primaryLabel,
                      loadingLabel: l10n.loading,
                      isLoading: isLoading,
                      onPressed: onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
