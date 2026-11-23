import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/presentation/notification_text.dart';

/// Notification rows. Unread rows use the pale brand fill.
class NotificationListBody extends StatelessWidget {
  const NotificationListBody({
    required this.items,
    required this.onOpen,
    required this.onMarkAll,
    this.markAllEnabled = true,
    this.onLoadMore,
    super.key,
  });

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onOpen;
  final VoidCallback onMarkAll;
  final bool markAllEnabled;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final when = DateFormat.yMMMd(locale.toString()).add_jm();
    final hasUnread = items.any((item) => item.isUnread);

    return ListView.separated(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      itemCount: items.length + 1 + (onLoadMore == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: markAllEnabled && hasUnread ? onMarkAll : null,
              child: Text(l10n.notificationsMarkAll),
            ),
          );
        }
        final itemIndex = index - 1;
        if (itemIndex >= items.length) {
          return OutlinedButton(
            onPressed: onLoadMore,
            child: Text(l10n.loadMore),
          );
        }
        final item = items[itemIndex];
        final unread = item.isUnread;
        return Material(
          key: Key('notification-${item.id}'),
          color: unread ? AppColors.paleBlue : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: Semantics(
            label: unread ? l10n.notificationsUnread : null,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onOpen(item),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificationTitle(l10n, item, languageCode),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificationBody(l10n, item, languageCode),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      when.format(item.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
