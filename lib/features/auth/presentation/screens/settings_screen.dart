import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/segmented_switch.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/change_password_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/logout_confirmation.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/account_header.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Language, password, and sign-out for every role.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscureCurrent = true;
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final saved = await ref
        .read(changePasswordControllerProvider.notifier)
        .submit(
          currentPassword: _currentController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );
    if (!mounted || !saved) return;
    _currentController.clear();
    _passwordController.clear();
    _confirmController.clear();
    setState(() => _autovalidateMode = AutovalidateMode.disabled);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.changePasswordSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final passwordState = ref.watch(changePasswordControllerProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user?.role == UserRole.driver) {
      ref.watch(driverTripsProvider(user!.id));
    }

    final banner = passwordState.rateLimited
        ? l10n.changePasswordRateLimited
        : passwordState.fieldErrors.isEmpty
        ? passwordState.failure?.message(l10n)
        : null;

    return AppScaffold(
      title: l10n.settingsTitle,
      body: ListView(
        padding: GlassBarInset.listPadding(
          context,
          const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
        ),
        children: [
          if (user != null) ...[
            AccountHeader(user: user),
            const SizedBox(height: 16),
          ],
          FormSection(
            title: l10n.languageSection,
            icon: Icons.translate_rounded,
            children: [
              SegmentedSwitch<String>(
                options: [
                  SegmentOption(value: 'en', label: l10n.languageEnglish),
                  SegmentOption(value: 'ar', label: l10n.languageArabic),
                ],
                selected: locale.languageCode,
                onChanged: (code) => unawaited(
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(Locale(code)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FormSection(
            title: l10n.changePasswordTitle,
            icon: Icons.lock_outline_rounded,
            children: [
          Form(
            key: _formKey,
            autovalidateMode: passwordState.fieldErrors.isNotEmpty
                ? AutovalidateMode.always
                : _autovalidateMode,
            child: Column(
              children: [
                AppTextField(
                  controller: _currentController,
                  label: l10n.currentPasswordLabel,
                  enabled: !passwordState.isLoading,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.lock_outline,
                  suffix: PasswordVisibilityButton(
                    obscure: _obscureCurrent,
                    onPressed: passwordState.isLoading
                        ? null
                        : () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                  ),
                  onChanged: (_) => ref
                      .read(changePasswordControllerProvider.notifier)
                      .clearFailure(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationPasswordRequired;
                    }
                    return passwordState.fieldErrors[ApiJsonKeys
                        .currentPassword];
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.newPasswordLabel,
                  enabled: !passwordState.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.lock_outline,
                  suffix: PasswordVisibilityButton(
                    obscure: _obscurePassword,
                    onPressed: passwordState.isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                  ),
                  onChanged: (_) {
                    ref
                        .read(changePasswordControllerProvider.notifier)
                        .clearFailure();
                    setState(() {});
                  },
                  validator: (value) =>
                      AuthValidators.password(value, l10n) ??
                      passwordState.fieldErrors[ApiJsonKeys.password],
                ),
                PasswordStrengthMeter(password: _passwordController.text),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmController,
                  label: l10n.confirmPasswordLabel,
                  enabled: !passwordState.isLoading,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  suffix: PasswordVisibilityButton(
                    obscure: _obscureConfirm,
                    onPressed: passwordState.isLoading
                        ? null
                        : () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                  ),
                  onFieldSubmitted: (_) => unawaited(_changePassword()),
                  onChanged: (_) => ref
                      .read(changePasswordControllerProvider.notifier)
                      .clearFailure(),
                  validator: (value) =>
                      AuthValidators.confirmPassword(
                        value,
                        _passwordController.text,
                        l10n,
                      ) ??
                      passwordState.fieldErrors[ApiJsonKeys
                          .passwordConfirmation],
                ),
              ],
            ),
          ),
          AnimatedErrorBanner(message: banner),
          AppButton(
            label: l10n.changePasswordAction,
            loadingLabel: l10n.loading,
            isLoading: passwordState.isLoading,
            onPressed: () => unawaited(_changePassword()),
          ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.settingsReplayGuide,
            variant: AppButtonVariant.tonal,
            icon: Icons.slideshow_rounded,
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: l10n.signOut,
            variant: AppButtonVariant.outlined,
            onPressed: () => unawaited(confirmAndSignOut(ref, context)),
          ),
        ],
      ),
    );
  }
}
