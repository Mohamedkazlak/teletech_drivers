import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/list_failure_view.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/notification/presentation/notification_destination.dart';
import 'package:teletech_drivers/features/notification/presentation/providers/notification_providers.dart';
import 'package:teletech_drivers/features/notification/presentation/widgets/notification_list_body.dart';

/// Inbox for every role. Tapping a row marks it read and opens its screen.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(notificationInboxProvider);
    final actions = ref.watch(notificationActionsProvider);
    final user = ref.watch(currentUserProvider).asData?.value;

    return AppScaffold(
      title: l10n.notificationsTitle,
      showBackButton: true,
      body: Column(
        children: [
          AnimatedErrorBanner(message: actions.failure?.message(l10n)),
          Expanded(
            child: inbox.when(
              skipLoadingOnReload: true,
              loading: () =>
                  Center(child: AppLoadingIndicator(label: l10n.loading)),
              error: (error, _) => ListFailureView(
                message: messageForError(error, l10n),
                onRetry: () => ref.invalidate(notificationInboxProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l10n.notificationsEmpty,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return NotificationListBody(
                  items: page.items,
                  markAllEnabled: !actions.isLoading,
                  onLoadMore: page.canLoadMore
                      ? () => ref
                            .read(notificationActionsProvider.notifier)
                            .loadMore()
                      : null,
                  onMarkAll: () {
                    ref.read(notificationActionsProvider.notifier).markAll();
                  },
                  onOpen: (item) async {
                    final opened = await ref
                        .read(notificationActionsProvider.notifier)
                        .markRead(item.id);
                    if (!opened || !context.mounted || user == null) return;
                    final location = notificationLocation(
                      role: user.role,
                      notification: item,
                    );
                    if (location == null || !context.mounted) return;
                    context.push(location);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
