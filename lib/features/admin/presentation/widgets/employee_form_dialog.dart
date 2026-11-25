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
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/form_sheet.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';

/// Create or edit an employee (name en/ar, phone, email, branch).
class EmployeeFormDialog extends ConsumerStatefulWidget {
  const EmployeeFormDialog({this.employee, super.key});

  final AppUser? employee;

  static Future<bool?> show(BuildContext context, {AppUser? employee}) {
    return showFormSheet<bool>(
      context,
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
  var _shake = 0;

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
      setState(() => _shake++);
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

    final busy = formState.isLoading;
    return FormSheet(
      title: _isEdit ? l10n.adminEditEmployeeTitle : l10n.adminAddEmployeeTitle,
      subtitle: _isEdit ? widget.employee!.email : null,
      icon: _isEdit ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
      formKey: _formKey,
      isLoading: busy,
      shakeTrigger: _shake,
      errorMessage: formState.failure?.message(l10n),
      primaryLabel: _isEdit ? l10n.adminSaveEmployee : l10n.adminAddEmployee,
      onPrimary: _submit,
      children: [
        FormSection(
          title: l10n.formSectionPersonal,
          icon: Icons.badge_outlined,
          children: [
            TextFormField(
              controller: _nameEnController,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.driverNameEnLabel),
              validator: (value) => EmployeeValidators.nameEn(value, l10n),
            ),
            TextFormField(
              controller: _nameArController,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.driverNameArLabel),
              validator: (value) => EmployeeValidators.nameAr(value, l10n),
            ),
          ],
        ),
        FormSection(
          title: l10n.formSectionContact,
          icon: Icons.alternate_email_rounded,
          children: [
            if (!_isEdit)
              TextFormField(
                controller: _emailController,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) => EmployeeValidators.email(value, l10n),
              ),
            TextFormField(
              controller: _phoneController,
              enabled: !busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (value) => EmployeeValidators.phone(value, l10n),
            ),
          ],
        ),
        FormSection(
          title: l10n.formSectionWork,
          icon: Icons.apartment_outlined,
          children: [
            DropdownButtonFormField<Branch>(
              // ignore: deprecated_member_use
              value: _branch,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.branchLabel),
              items: [
                for (final branch in Branch.values)
                  DropdownMenuItem(
                    value: branch,
                    child: Text(branchLabel(branch, l10n)),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() => _branch = value),
              validator: (_) => EmployeeValidators.branch(_branch, l10n),
            ),
          ],
        ),
        if (!_isEdit)
          FormSection(
            title: l10n.formSectionAccess,
            icon: Icons.lock_outline_rounded,
            children: [
              TextFormField(
                controller: _passwordController,
                enabled: !busy,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autocorrect: false,
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
          ),
      ],
    );
  }
}
