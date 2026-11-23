import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/company_admin/presentation/state/admin_action_state.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/invalidate_trip_request_providers.dart';

/// Dependency Injection: Riverpod.
final rejectTripRequestControllerProvider =
    NotifierProvider.autoDispose<RejectTripRequestController, AdminActionState>(
      RejectTripRequestController.new,
    );

class RejectTripRequestController extends Notifier<AdminActionState> {
  @override
  AdminActionState build() => const AdminActionState();

  /// Returns true when the request was rejected successfully.
  Future<bool> reject({
    required String requestId,
    String? reason,
  }) async {
    if (state.isLoading) return false;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      state = const AdminActionState(failure: UnknownFailure());
      return false;
    }

    state = AdminActionState(isLoading: true, activeRequestId: requestId);
    try {
      await ref.read(rejectPendingTripRequestUseCaseProvider)(
        requestId: requestId,
        handledByUid: user.id,
        handledByName: user.name,
        reason: reason,
      );
      if (!ref.mounted) return false;
      invalidateTripRequestProviders(ref);
      state = const AdminActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = AdminActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const AdminActionState(failure: UnknownFailure());
      return false;
    }
  }
}
