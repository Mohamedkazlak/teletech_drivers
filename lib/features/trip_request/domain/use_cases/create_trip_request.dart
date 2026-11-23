import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/create_trip_request_result.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class CreateTripRequestUseCase {
  const CreateTripRequestUseCase(this._repository);

  final TripRequestRepository _repository;

  /// Sends the request; the server derives status, auto-approval and trip
  /// creation from the authenticated user's role, so the plan fields below
  /// are placeholders.
  Future<CreateTripRequestResult> call({
    required UserRole requesterRole,
    required String employeeId,
    required String employeeName,
    required Branch employeeBranch,
    required String employeePhone,
    required String pickupPlaceId,
    required String pickupPlaceName,
    required String destinationPlaceId,
    required String destinationPlaceName,
    required DateTime requestedDateTime,
    required String notes,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
  }) {
    return _repository.createRequest(
      employeeId: employeeId,
      employeeName: employeeName.trim(),
      employeeBranch: employeeBranch,
      employeePhone: employeePhone.trim(),
      pickupPlaceId: pickupPlaceId,
      pickupPlaceName: pickupPlaceName.trim(),
      destinationPlaceId: destinationPlaceId,
      destinationPlaceName: destinationPlaceName.trim(),
      requestedDateTime: requestedDateTime,
      notes: notes.trim(),
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress?.trim(),
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      destinationAddress: destinationAddress?.trim(),
      status: TripRequestStatus.pending,
      autoApproved: false,
      requesterRole: requesterRole.name,
      createTrip: false,
    );
  }
}
