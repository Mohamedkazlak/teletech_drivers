import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Bottom sheet listing active drivers for assignment / reassignment.
///
/// Recommended drivers appear first; unavailable / conflicting drivers stay
/// selectable with a warning confirm dialog (never hidden or disabled).
class DriverPickerSheet extends ConsumerWidget {
  const DriverPickerSheet({
    required this.trip,
    this.excludeDriverId,
    super.key,
  });

  final Trip trip;
  final String? excludeDriverId;

  static Future<DriverProfile?> show(
    BuildContext context, {
    required Trip trip,
    String? excludeDriverId,
  }) {
    return showModalBottomSheet<DriverProfile>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) =>
          DriverPickerSheet(trip: trip, excludeDriverId: excludeDriverId),
    );
  }

  Future<void> _onDriverSelected(
    BuildContext context,
    DriverRecommendation recommendation,
  ) async {
    final l10n = AppLocalizations.of(context);

    if (recommendation.needsConfirmation) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.assignDriverWarningTitle),
            content: Text(l10n.assignDriverWarningMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.dialogCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.assignDriverWarningContinue),
              ),
            ],
          );
        },
      );
      if (proceed != true || !context.mounted) return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(recommendation.driver);
  }

  String _reasonLabel(
    AppLocalizations l10n,
    DriverRecommendationReason reason,
  ) {
    return switch (reason) {
      DriverRecommendationReason.favoritePlace =>
        l10n.driverReasonFavoritePlace,
      DriverRecommendationReason.available => l10n.driverReasonAvailable,
      DriverRecommendationReason.unavailable => l10n.driverReasonUnavailable,
      DriverRecommendationReason.onActiveTrip => l10n.driverReasonOnActiveTrip,
      DriverRecommendationReason.scheduleConflict =>
        l10n.driverReasonScheduleConflict,
    };
  }

  bool _isWarningReason(DriverRecommendationReason reason) {
    return reason == DriverRecommendationReason.unavailable ||
        reason == DriverRecommendationReason.onActiveTrip ||
        reason == DriverRecommendationReason.scheduleConflict;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final recommendationsAsync = ref.watch(driverRecommendationsProvider(trip.id));

    // Fixed height avoids Column(min) + shrinkWrap ListView intrinsic crash.
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.6;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.selectDriverTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: recommendationsAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppLoadingIndicator(label: l10n.loading),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      messageForError(error, l10n),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (ranked) {
                    final selectable = [
                      for (final item in ranked)
                        if (item.driver.id != excludeDriverId) item,
                    ];

                    if (selectable.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.noActiveDriversMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    final recommended = [
                      for (final item in selectable)
                        if (item.isRecommended) item,
                    ];
                    final others = [
                      for (final item in selectable)
                        if (!item.isRecommended) item,
                    ];

                    return ListView(
                      children: [
                        if (recommended.isNotEmpty) ...[
                          _SectionHeader(title: l10n.recommendedDriversSection),
                          for (final item in recommended)
                            _tile(context, l10n, languageCode, item),
                        ],
                        if (others.isNotEmpty) ...[
                          _SectionHeader(title: l10n.otherDriversSection),
                          for (final item in others)
                            _tile(context, l10n, languageCode, item),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    AppLocalizations l10n,
    String languageCode,
    DriverRecommendation item,
  ) {
    return _DriverRecommendationTile(
      recommendation: item,
      languageCode: languageCode,
      carLine: item.driver.carLicense.isEmpty
          ? l10n.carLicenseNotSet
          : l10n.carLicenseValue(item.driver.carLicense),
      reasonLabel: (reason) => _reasonLabel(l10n, reason),
      isWarningReason: _isWarningReason,
      onTap: () => _onDriverSelected(context, item),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AppColors.navy.withValues(alpha: 0.7)),
      ),
    );
  }
}

class _DriverRecommendationTile extends StatelessWidget {
  const _DriverRecommendationTile({
    required this.recommendation,
    required this.languageCode,
    required this.carLine,
    required this.reasonLabel,
    required this.isWarningReason,
    required this.onTap,
  });

  final DriverRecommendation recommendation;
  final String languageCode;
  final String carLine;
  final String Function(DriverRecommendationReason reason) reasonLabel;
  final bool Function(DriverRecommendationReason reason) isWarningReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWarning = recommendation.needsConfirmation;

    return ListTile(
      onTap: onTap,
      isThreeLine: true,
      title: Text(recommendation.driver.localizedName(languageCode)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final reason in recommendation.reasons)
                Chip(
                  label: Text(
                    reasonLabel(reason),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isWarningReason(reason)
                          ? AppColors.error
                          : AppColors.navy,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(
                    color: isWarningReason(reason)
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.navy.withValues(alpha: 0.25),
                  ),
                  backgroundColor: isWarningReason(reason)
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.navy.withValues(alpha: 0.06),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).recommendationTier(recommendation.tier),
          ),
          Text(
            AppLocalizations.of(context).recommendationTripsThisWeek(
              recommendation.tripsThisWeek,
            ),
          ),
          Text(carLine),
        ],
      ),
      trailing: hasWarning
          ? Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error)
          : null,
    );
  }
}
