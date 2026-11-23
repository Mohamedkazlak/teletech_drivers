import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Horizontal filter for all / company headquarters / new headquarters.
class BranchFilterBar extends StatelessWidget {
  const BranchFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Branch? selected;
  final ValueChanged<Branch?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.branchFilterAll),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final branch in Branch.values) ...[
            FilterChip(
              label: Text(branchLabel(branch, l10n)),
              selected: selected == branch,
              onSelected: (_) => onChanged(branch),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
