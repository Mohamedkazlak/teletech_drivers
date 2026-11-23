import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Dashboard tile: icon, title, optional count, taps to a section.
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.count,
    this.subtitle,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.deepBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.deepBlue),
                    const Spacer(),
                    if (count != null)
                      Text(
                        '$count',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.deepBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
