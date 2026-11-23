import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/role_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/update_profile_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';

/// Editable English name, Arabic name, email, and phone.
/// Role stays read-only. Branch is editable for a system admin only.
/// Only changed fields are sent.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Branch? _branch;
  var _seeded = false;
  var _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _seed(AppUser user) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = user.nameEn?.trim().isNotEmpty == true
        ? user.nameEn!.trim()
        : user.name;
    _nameArController.text = user.nameAr ?? '';
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
    _branch = user.branch;
  }

  Future<void> _submit(AppUser? user) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final lockBranch = user?.role != UserRole.admin;
    final branch = lockBranch
        ? (user?.branch ?? Branch.companyHeadquarters)
        : _branch;
    if (branch == null) return;

    final saved = await ref
        .read(updateProfileControllerProvider.notifier)
        .submit(
          nameEn: _nameController.text,
          nameAr: _nameArController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          branch: branch,
          lockBranch: lockBranch,
        );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final form = ref.watch(updateProfileControllerProvider);
    if (user != null) _seed(user);

    final banner = form.fieldErrors.isEmpty
        ? form.failure?.message(l10n)
        : null;

    return AppScaffold(
      title: l10n.profileTitle,
      body: user == null
          ? Center(child: Text(l10n.homeEmpty))
          : Form(
              key: _formKey,
              autovalidateMode: form.fieldErrors.isNotEmpty
                  ? AutovalidateMode.always
                  : _autovalidateMode,
              child: ListView(
                padding: GlassBarInset.listPadding(
                  context,
                  const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
                ),
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: l10n.driverNameEnLabel,
                    enabled: !form.isLoading,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: Icons.badge_outlined,
                    onChanged: (_) => ref
                        .read(updateProfileControllerProvider.notifier)
                        .clearFailure(),
                    validator: (value) =>
                        AuthValidators.name(value, l10n) ??
                        form.fieldErrors[ApiJsonKeys.nameEn],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameArController,
                    label: l10n.driverNameArLabel,
                    enabled: !form.isLoading,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: Icons.badge_outlined,
                    onChanged: (_) => ref
                        .read(updateProfileControllerProvider.notifier)
                        .clearFailure(),
                    validator: (value) => form.fieldErrors[ApiJsonKeys.nameAr],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: l10n.emailLabel,
                    enabled: !form.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    prefixIcon: Icons.email_outlined,
                    onChanged: (_) => ref
                        .read(updateProfileControllerProvider.notifier)
                        .clearFailure(),
                    validator: (value) =>
                        AuthValidators.email(value, l10n) ??
                        form.fieldErrors[ApiJsonKeys.email],
                  ),
                  const SizedBox(height: 16),
                  _ReadOnlyField(
                    label: l10n.roleFieldLabel,
                    value: roleLabel(user.role, l10n),
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    label: l10n.phoneLabel,
                    enabled: !form.isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.phone_outlined,
                    onChanged: (_) => ref
                        .read(updateProfileControllerProvider.notifier)
                        .clearFailure(),
                    validator: (value) =>
                        AuthValidators.phone(value, l10n) ??
                        form.fieldErrors[ApiJsonKeys.phone],
                  ),
                  const SizedBox(height: 16),
                  if (user.role == UserRole.admin)
                    DropdownButtonFormField<Branch>(
                      // ignore: deprecated_member_use
                      value: _branch,
                      decoration: InputDecoration(
                        labelText: l10n.branchLabel,
                        prefixIcon: const Icon(Icons.apartment_outlined),
                        errorText: form.fieldErrors[ApiJsonKeys.branch],
                      ),
                      items: [
                        for (final branch in Branch.values)
                          DropdownMenuItem(
                            value: branch,
                            child: Text(branchLabel(branch, l10n)),
                          ),
                      ],
                      onChanged: form.isLoading
                          ? null
                          : (value) {
                              setState(() => _branch = value);
                              ref
                                  .read(
                                    updateProfileControllerProvider.notifier,
                                  )
                                  .clearFailure();
                            },
                      validator: (value) => AuthValidators.branch(value, l10n),
                    )
                  else ...[
                    _ReadOnlyField(
                      label: l10n.branchLabel,
                      value: user.branch == null
                          ? ''
                          : branchLabel(user.branch!, l10n),
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.branchLockedHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  AnimatedErrorBanner(message: banner),
                  const SizedBox(height: 24),
                  AppButton(
                    label: l10n.profileSave,
                    loadingLabel: l10n.loading,
                    isLoading: form.isLoading,
                    onPressed: () => unawaited(_submit(user)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        enabled: false,
      ),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
