import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/register_employee_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';

class RegisterEmployeeScreen extends ConsumerStatefulWidget {
  const RegisterEmployeeScreen({super.key});

  @override
  ConsumerState<RegisterEmployeeScreen> createState() =>
      _RegisterEmployeeScreenState();
}

class _RegisterEmployeeScreenState
    extends ConsumerState<RegisterEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Branch? _branch;
  var _autovalidateMode = AutovalidateMode.disabled;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearFailure() {
    ref.read(registerEmployeeControllerProvider.notifier).clearFailure();
  }

  void _onPasswordChanged(String _) {
    _clearFailure();
    if (_autovalidateMode == AutovalidateMode.onUserInteraction) {
      _formKey.currentState?.validate();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final branch = _branch;
    if (branch == null) return;

    await ref
        .read(registerEmployeeControllerProvider.notifier)
        .submit(
          name: _nameController.text,
          nameAr: _nameArController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          phone: _phoneController.text,
          branch: branch,
        );
    if (!mounted) return;
    if (ref.read(registerEmployeeControllerProvider).failure == null) {
      TextInput.finishAutofillContext();
    }
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(registerEmployeeControllerProvider);
    final failure = state.failure;
    final detailsComplete =
        _nameController.text.trim().isNotEmpty &&
        _nameArController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _branch != null;

    return AuthPageScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: AuthStagger(
            children: [
              AuthSectionProgress(
                currentStep: detailsComplete ? 1 : 0,
                totalSteps: 2,
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.registerSectionDetails),
              const SizedBox(height: 10),
              AppTextField(
                controller: _nameController,
                label: l10n.driverNameEnLabel,
                enabled: !state.isLoading,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                prefixIcon: Icons.person_outline,
                onChanged: (_) {
                  _clearFailure();
                  setState(() {});
                },
                validator: (value) => AuthValidators.name(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameArController,
                label: l10n.driverNameArLabel,
                enabled: !state.isLoading,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                onChanged: (_) {
                  _clearFailure();
                  setState(() {});
                },
                validator: (value) => AuthValidators.name(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: l10n.emailLabel,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                prefixIcon: Icons.email_outlined,
                onChanged: (_) {
                  _clearFailure();
                  setState(() {});
                },
                validator: (value) => AuthValidators.email(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: l10n.phoneLabel,
                enabled: !state.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                prefixIcon: Icons.phone_outlined,
                onChanged: (_) {
                  _clearFailure();
                  setState(() {});
                },
                validator: (value) => AuthValidators.phone(value, l10n),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Branch>(
                // ignore: deprecated_member_use
                value: _branch,
                decoration: InputDecoration(
                  labelText: l10n.branchLabel,
                  prefixIcon: const Icon(Icons.apartment_outlined),
                ),
                items: [
                  for (final branch in Branch.values)
                    DropdownMenuItem(
                      value: branch,
                      child: Text(branchLabel(branch, l10n)),
                    ),
                ],
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        FocusScope.of(context).unfocus();
                        setState(() => _branch = value);
                        _clearFailure();
                      },
                validator: (value) => AuthValidators.branch(value, l10n),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: l10n.registerSectionSecurity),
              const SizedBox(height: 10),
              AppTextField(
                controller: _passwordController,
                label: l10n.passwordLabel,
                enabled: !state.isLoading,
                obscureText: _obscurePassword,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline,
                onChanged: _onPasswordChanged,
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
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordController,
                label: l10n.confirmPasswordLabel,
                enabled: !state.isLoading,
                obscureText: _obscureConfirmPassword,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_person_outlined,
                onChanged: (_) => _clearFailure(),
                onFieldSubmitted: (_) => unawaited(_submit()),
                validator: (value) => AuthValidators.confirmPassword(
                  value,
                  _passwordController.text,
                  l10n,
                ),
                suffix: PasswordVisibilityButton(
                  obscure: _obscureConfirmPassword,
                  onPressed: state.isLoading
                      ? null
                      : () => setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }),
                ),
              ),
              AnimatedErrorBanner(message: failure?.message(l10n)),
              if (failure != null) const SizedBox(height: 8),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.createEmployeeAccount,
                loadingLabel: l10n.loading,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isLoading ? null : _backToLogin,
                child: Text(l10n.alreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: AppColors.midBlue),
    );
  }
}
