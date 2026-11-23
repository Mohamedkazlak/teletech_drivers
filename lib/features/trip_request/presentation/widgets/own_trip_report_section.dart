import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/confirm_trip_form.dart';

/// Request the signed-in user may confirm, or null for everyone else.
String? ownPendingReportRequestId(AppUser? user, Trip trip) {
  if (user == null || !_canFileReport(user.role)) return null;
  return trip.pendingReportRequestIdFor(user.id);
}

/// Employee report, shown only when the signed-in user requested this trip.
class OwnTripReportSection extends ConsumerWidget {
  const OwnTripReportSection({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestId = ownPendingReportRequestId(
      ref.watch(currentUserProvider).asData?.value,
      trip,
    );
    if (requestId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ConfirmTripForm(requestId: requestId),
    );
  }
}

bool _canFileReport(UserRole role) {
  return role == UserRole.employee ||
      role == UserRole.companyAdmin ||
      role == UserRole.driversAdmin;
}
