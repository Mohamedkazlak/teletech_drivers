import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_connection.dart';
import 'package:teletech_drivers/features/realtime/presentation/providers/realtime_providers.dart';

/// Small live/offline label. Hidden when the socket is not configured.
class RealtimeConnectionIndicator extends ConsumerWidget {
  const RealtimeConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(realtimeSessionProvider);
    if (connection == RealtimeConnection.disabled) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final label = switch (connection) {
      RealtimeConnection.connected => l10n.realtimeConnected,
      RealtimeConnection.connecting => l10n.realtimeConnecting,
      RealtimeConnection.disconnected => l10n.realtimeDisconnected,
      RealtimeConnection.disabled => '',
    };
    final color = switch (connection) {
      RealtimeConnection.connected => const Color(0xFF0F766E),
      RealtimeConnection.connecting => const Color(0xFFB45309),
      _ => const Color(0xFF64748B),
    };

    return Semantics(
      label: label,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
