import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/requester_contact_section.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_requester.dart';

/// Requester name, tap-to-call phone, and the server passenger count.
///
/// A grouped trip lists every requester. The count is [passengerCount]
/// from the API, not a client recount of names.
class TripRequestersSection extends StatelessWidget {
  const TripRequestersSection({
    required this.requesters,
    required this.passengerCount,
    super.key,
  });

  final List<TripRequester> requesters;
  final int passengerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final grouped = requesters.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grouped) ...[
          Text(l10n.requestersSection, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var index = 0; index < requesters.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            RequesterContactSection(
              name: requesters[index].localizedName(languageCode),
              branch: requesters[index].branch,
              phone: requesters[index].phone,
              showHeading: false,
            ),
          ],
        ] else if (requesters.isNotEmpty)
          RequesterContactSection(
            name: requesters.first.localizedName(languageCode),
            branch: requesters.first.branch,
            phone: requesters.first.phone,
          ),
        if (requesters.isNotEmpty) const SizedBox(height: 4),
        Text(
          l10n.passengersCountLabel(passengerCount),
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
