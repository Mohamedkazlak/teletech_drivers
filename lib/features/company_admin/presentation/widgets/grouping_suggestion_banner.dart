import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

/// Dismissible banner: N pending requests look groupable.
class GroupingSuggestionBanner extends StatelessWidget {
  const GroupingSuggestionBanner({
    required this.requestCount,
    required this.onTap,
    required this.onDismiss,
    super.key,
  });

  final int requestCount;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
          child: Row(
            children: [
              Icon(
                Icons.group_work_outlined,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.groupingSuggestionBanner(requestCount),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
              ),
              IconButton(
                tooltip: l10n.groupingSuggestionDismiss,
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
