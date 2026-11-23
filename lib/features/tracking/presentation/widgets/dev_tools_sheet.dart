import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/trip_navigation_controller.dart';

/// Debug-only sheet: simulate movement along the loaded route.
Future<void> showDevToolsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String tripId,
}) async {
  assert(kDebugMode, 'Dev tools must not open in release');
  if (!kDebugMode) return;

  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final nav = ref.watch(tripNavigationControllerProvider(tripId));
          final notifier = ref.read(
            tripNavigationControllerProvider(tripId).notifier,
          );
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.devToolsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.devSimulateMovement),
                  value: nav.simulating,
                  onChanged: (value) => notifier.setSimulating(value),
                ),
                Text(l10n.devSimulateSpeed(nav.simulateSpeedKmh.round())),
                Slider(
                  value: nav.simulateSpeedKmh,
                  min: 10,
                  max: 120,
                  divisions: 22,
                  label: '${nav.simulateSpeedKmh.round()}',
                  onChanged: nav.simulating
                      ? notifier.setSimulateSpeed
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: nav.simulating
                            ? () => notifier.setSimulatePaused(!nav.simulatePaused)
                            : null,
                        child: Text(
                          nav.simulatePaused
                              ? l10n.devResumeSimulation
                              : l10n.devPauseSimulation,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepBlue,
                        ),
                        onPressed: nav.simulating
                            ? () => notifier.jumpSimulatorToPercent(0.9)
                            : null,
                        child: Text(l10n.devJumpToNinety),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
