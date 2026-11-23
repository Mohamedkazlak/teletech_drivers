import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/reset_user_password_controller.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';

/// System admin sets a temporary password the user must replace on sign-in.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  const ResetPasswordDialog({required this.user, super.key});

  final AppUser user;

  static Future<bool?> show(BuildContext context, {required AppUser user}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ResetPasswordDialog(user: user),
    );
  }

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final succeeded = await ref
        .read(resetUserPasswordControllerProvider.notifier)
        .submit(userId: widget.user.id, password: _passwordController.text);
    if (!mounted || !succeeded) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final formState = ref.watch(resetUserPasswordControllerProvider);
    final name = widget.user.localizedName(languageCode);

    return AlertDialog(
      title: Text(l10n.adminResetPasswordTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.adminResetPasswordMessage(name)),
              const SizedBox(height: 12),
              Text(
                l10n.adminResetPasswordNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (formState.failure != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: formState.failure!.message(l10n)),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !formState.isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.temporaryPasswordLabel,
                  suffixIcon: PasswordVisibilityButton(
                    obscure: _obscurePassword,
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) => AuthValidators.password(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                enabled: !formState.isLoading,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                  suffixIcon: PasswordVisibilityButton(
                    obscure: _obscureConfirm,
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                validator: (value) => AuthValidators.confirmPassword(
                  value,
                  _passwordController.text,
                  l10n,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: formState.isLoading ? null : _submit,
          child: formState.isLoading
              ? SizedBox.square(
                  dimension: 20,
                  child: Semantics(
                    label: l10n.loading,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(l10n.adminResetPasswordAction),
        ),
      ],
    );
  }
}
