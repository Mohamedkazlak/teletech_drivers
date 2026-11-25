import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';

/// A group of related form fields on one white card.
///
/// Long forms read as a few clear steps instead of one column of inputs.
/// [title] is optional; the fields' own labels often say enough.
class FormSection extends StatelessWidget {
  const FormSection({
    required this.children,
    this.title,
    this.icon,
    this.spacing = 12,
    super.key,
  });

  final String? title;
  final IconData? icon;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.deepBlue),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(title!, style: textTheme.titleSmall)),
                ],
              ),
              SizedBox(height: spacing + 2),
            ],
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Read-only field that opens a picker (date, time, …) when tapped.
///
/// Looks like the other inputs, and the whole field is the tap target.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
    this.icon,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final IconData? icon;
  final String? errorText;

  /// Null disables the field.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasValue = value != null && value!.isNotEmpty;
    return Semantics(
      button: true,
      label: label,
      value: value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InputDecorator(
          isEmpty: !hasValue,
          decoration: InputDecoration(
            labelText: label,
            // Keep the label above the field when a placeholder is shown, so
            // the two never draw on top of each other.
            floatingLabelBehavior: placeholder == null
                ? null
                : FloatingLabelBehavior.always,
            prefixIcon: icon == null ? null : Icon(icon),
            suffixIcon: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.inkMuted,
            ),
            errorText: errorText,
            enabled: onTap != null,
          ),
          child: Text(
            hasValue ? value! : (placeholder ?? ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: hasValue ? AppColors.navy : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tonal action under a field (e.g. "Choose on map").
class FieldAction extends StatelessWidget {
  const FieldAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.paleBlue,
          foregroundColor: AppColors.deepBlue,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Bottom bar that keeps a form's main action in thumb reach.
class FormActionBar extends StatelessWidget {
  const FormActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}
