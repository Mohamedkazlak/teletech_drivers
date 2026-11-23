import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/create_employee_controller.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/update_employee_controller.dart';
import 'package:teletech_drivers/features/admin/presentation/validation/employee_validators.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';

/// Create or edit an employee (name en/ar, phone, email, branch).
class EmployeeFormDialog extends ConsumerStatefulWidget {
  const EmployeeFormDialog({this.employee, super.key});

  final AppUser? employee;

  static Future<bool?> show(BuildContext context, {AppUser? employee}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => EmployeeFormDialog(employee: employee),
    );
  }

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  Branch? _branch;
  var _obscurePassword = true;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameEnController = TextEditingController(
      text: employee?.nameEn ?? employee?.name ?? '',
    );
    _nameArController = TextEditingController(
      text: employee?.nameAr ?? employee?.name ?? '',
    );
    _emailController = TextEditingController(text: employee?.email ?? '');
    _phoneController = TextEditingController(text: employee?.phone ?? '');
    _passwordController = TextEditingController();
    _branch = employee?.branch;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final formValid = _formKey.currentState?.validate() ?? false;
    final branchError = EmployeeValidators.branch(_branch, l10n);
    if (!formValid || branchError != null) {
      if (branchError != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(branchError)));
      }
      return;
    }

    final branch = _branch!;
    final bool succeeded;
    if (_isEdit) {
      succeeded = await ref
          .read(updateEmployeeControllerProvider.notifier)
          .submit(
            employeeId: widget.employee!.id,
            nameEn: _nameEnController.text,
            nameAr: _nameArController.text,
            phone: _phoneController.text,
            branch: branch,
          );
    } else {
      succeeded = await ref
          .read(createEmployeeControllerProvider.notifier)
          .submit(
            nameEn: _nameEnController.text,
            nameAr: _nameArController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            branch: branch,
          );
    }

    if (!mounted || !succeeded) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = _isEdit
        ? ref.watch(updateEmployeeControllerProvider)
        : ref.watch(createEmployeeControllerProvider);

    return AlertDialog(
      title: Text(
        _isEdit ? l10n.adminEditEmployeeTitle : l10n.adminAddEmployeeTitle,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (formState.failure != null) ...[
                AuthErrorBanner(message: formState.failure!.message(l10n)),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameEnController,
                enabled: !formState.isLoading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.driverNameEnLabel),
                validator: (value) => EmployeeValidators.nameEn(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameArController,
                enabled: !formState.isLoading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.driverNameArLabel),
                validator: (value) => EmployeeValidators.nameAr(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                enabled: !formState.isLoading && !_isEdit,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) => EmployeeValidators.email(value, l10n),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !formState.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    suffixIcon: PasswordVisibilityButton(
                      obscure: _obscurePassword,
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) => AuthValidators.password(value, l10n),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                enabled: !formState.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
                validator: (value) => EmployeeValidators.phone(value, l10n),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Branch>(
                // ignore: deprecated_member_use
                value: _branch,
                decoration: InputDecoration(labelText: l10n.branchLabel),
                items: [
                  for (final branch in Branch.values)
                    DropdownMenuItem(
                      value: branch,
                      child: Text(branchLabel(branch, l10n)),
                    ),
                ],
                onChanged: formState.isLoading
                    ? null
                    : (value) => setState(() => _branch = value),
                validator: (_) => EmployeeValidators.branch(_branch, l10n),
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
              : Text(_isEdit ? l10n.adminSaveEmployee : l10n.adminAddEmployee),
        ),
      ],
    );
  }
}
