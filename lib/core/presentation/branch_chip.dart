import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Compact chip showing a company branch on request and trip cards.
class BranchChip extends StatelessWidget {
  const BranchChip({required this.branch, super.key});

  final Branch? branch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (branch == null) return const SizedBox.shrink();

    return Chip(
      label: Text(branchLabel(branch!, l10n)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Shows one chip per unique branch (for multi-passenger trips).
class BranchChips extends StatelessWidget {
  const BranchChips({required this.branches, super.key});

  final List<Branch> branches;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final branch in branches) BranchChip(branch: branch),
      ],
    );
  }
}
