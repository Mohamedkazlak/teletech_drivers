import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';

/// Read-only timeline of the four trip lifecycle events.
class TripEventsSection extends StatelessWidget {
  const TripEventsSection({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tripEventsSection, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _TripEventLine(
          label: l10n.tripEventTripStarted,
          at: trip.goingStartedAt,
          pendingLabel: l10n.tripNotStartedYet,
          dateFormat: dateFormat,
        ),
        const SizedBox(height: 4),
        _TripEventLine(
          label: l10n.tripEventArrivedAtDestination,
          at: trip.goingEndedAt,
          pendingLabel: l10n.tripNotArrivedYet,
          dateFormat: dateFormat,
        ),
        const SizedBox(height: 4),
        _TripEventLine(
          label: l10n.tripEventStartedReturning,
          at: trip.returnStartedAt,
          pendingLabel: l10n.tripNotReturningYet,
          dateFormat: dateFormat,
        ),
        const SizedBox(height: 4),
        _TripEventLine(
          label: l10n.tripEventTripEnded,
          at: trip.finishedAt,
          pendingLabel: l10n.tripNotEndedYet,
          dateFormat: dateFormat,
        ),
      ],
    );
  }
}

class _TripEventLine extends StatelessWidget {
  const _TripEventLine({
    required this.label,
    required this.at,
    required this.pendingLabel,
    required this.dateFormat,
  });

  final String label;
  final DateTime? at;
  final String pendingLabel;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = at == null ? pendingLabel : dateFormat.format(at!.toLocal());

    return Text.rich(
      TextSpan(
        style: textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
