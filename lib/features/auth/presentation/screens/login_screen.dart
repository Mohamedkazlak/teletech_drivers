import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/sign_in_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _autovalidateMode = AutovalidateMode.disabled;
  var _shake = 0;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearFailure() {
    ref.read(signInControllerProvider.notifier).clearFailure();
    ref.read(authSessionFailureProvider.notifier).clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _shake++;
      });
      return;
    }

    ref.read(authSessionFailureProvider.notifier).clear();
    await ref
        .read(signInControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ref.read(signInControllerProvider).failure == null) {
      TextInput.finishAutofillContext();
    } else {
      setState(() => _shake++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(signInControllerProvider);
    final failure = state.failure ?? ref.watch(authSessionFailureProvider);

    return AuthPageScaffold(
      shakeTrigger: _shake,
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: AuthStagger(
            children: [
              AppTextField(
                controller: _emailController,
                label: l10n.emailLabel,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                prefixIcon: Icons.email_outlined,
                onChanged: (_) => _clearFailure(),
                validator: (value) => AuthValidators.email(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: l10n.passwordLabel,
                enabled: !state.isLoading,
                obscureText: _obscurePassword,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                prefixIcon: Icons.lock_outline,
                onChanged: (_) => _clearFailure(),
                onFieldSubmitted: (_) => unawaited(_submit()),
                validator: (value) => AuthValidators.password(value, l10n),
                suffix: PasswordVisibilityButton(
                  obscure: _obscurePassword,
                  onPressed: state.isLoading
                      ? null
                      : () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                ),
              ),
              AnimatedErrorBanner(message: failure?.message(l10n)),
              if (failure != null) const SizedBox(height: 8),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.signIn,
                loadingLabel: l10n.loading,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => context.push(AppRoutes.register),
                child: Text(l10n.createEmployeeAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
