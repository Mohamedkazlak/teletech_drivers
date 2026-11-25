import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/complete_profile_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_page_scaffold.dart';

/// Shown when an employee is missing branch or phone on their profile.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  Branch? _branch;
  var _autovalidateMode = AutovalidateMode.disabled;
  var _shake = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _shake++;
      });
      return;
    }
    final branch = _branch;
    if (branch == null) return;

    final succeeded = await ref
        .read(completeProfileControllerProvider.notifier)
        .submit(phone: _phoneController.text, branch: branch);

    if (!mounted) return;
    if (!succeeded) {
      setState(() => _shake++);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).completeProfileSaved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(completeProfileControllerProvider);
    final failure = state.failure;

    return AuthPageScaffold(
      shakeTrigger: _shake,
      title: l10n.completeProfileTitle,
      showSignOut: true,
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.completeProfileSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<Branch>(
              // ignore: deprecated_member_use
              value: _branch,
              isExpanded: true,
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
                      ref
                          .read(completeProfileControllerProvider.notifier)
                          .clearFailure();
                    },
              validator: (value) => AuthValidators.branch(value, l10n),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              label: l10n.phoneLabel,
              enabled: !state.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              prefixIcon: Icons.phone_outlined,
              onChanged: (_) => ref
                  .read(completeProfileControllerProvider.notifier)
                  .clearFailure(),
              onFieldSubmitted: (_) => unawaited(_submit()),
              validator: (value) => AuthValidators.phone(value, l10n),
            ),
            AnimatedErrorBanner(message: failure?.message(l10n)),
            if (failure != null) const SizedBox(height: 8),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.completeProfileSubmit,
              loadingLabel: l10n.loading,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
