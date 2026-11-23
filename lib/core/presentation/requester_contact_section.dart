import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/utils/phone_dialer.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Shows only the requesting employee's name, branch, and phone (tap to call).
/// Fellow passengers must appear only in free-text notes elsewhere.
class RequesterContactSection extends StatelessWidget {
  const RequesterContactSection({
    required this.name,
    this.branch,
    this.phone,
    this.showHeading = true,
    super.key,
  });

  final String name;
  final Branch? branch;
  final String? phone;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final phoneValue = phone?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(l10n.requesterSection, style: textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Text(name, style: textTheme.titleSmall),
        if (branch != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BranchChip(branch: branch),
          ),
        ],
        if (phoneValue != null && phoneValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined),
            title: Text(phoneValue),
            subtitle: Text(l10n.phoneLabel),
            onTap: () => PhoneDialer.dial(phoneValue),
            trailing: IconButton(
              tooltip: l10n.callEmployeePhone(phoneValue),
              icon: const Icon(Icons.call_outlined),
              onPressed: () => PhoneDialer.dial(phoneValue),
            ),
          ),
        ],
      ],
    );
  }
}
