import 'package:teletech_drivers/features/trip_request/data/models/group_suggestion_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/linked_trip_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/linked_trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Maps trip-request API DTOs onto domain entities.
abstract final class TripRequestDtoMapper {
  static TripRequest toEntity(TripRequestDto dto) {
    final employeeName =
        dto.employeeNameEn ?? dto.employeeNameAr ?? '';
    return TripRequest(
      id: dto.id,
      employeeId: dto.employeeId,
      employeeName: employeeName,
      employeeBranch: dto.employeeBranch,
      employeePhone: dto.employeePhone,
      pickupPlaceId: dto.pickup.placeId,
      pickupPlaceName: dto.pickup.name,
      pickupLat: dto.pickup.lat,
      pickupLng: dto.pickup.lng,
      pickupAddress: dto.pickup.address,
      destinationPlaceId: dto.destination.placeId,
      destinationPlaceName: dto.destination.name,
      destinationLat: dto.destination.lat,
      destinationLng: dto.destination.lng,
      destinationAddress: dto.destination.address,
      requestedDateTime: dto.requestedAt,
      notes: dto.notes,
      status: dto.status,
      tripId: dto.tripId,
      rejectionReason: dto.rejectionReason,
      handledByUid: dto.handledBy,
      handledByName: null,
      handledAt: dto.handledAt,
      autoApproved: dto.autoApproved,
      // Store [UserRole.name] so [TripRequest.isAdminRequest] keeps working.
      requesterRole: dto.requesterRole?.name,
      suggestedGroupId: dto.suggestedGroupId,
      createdAt: dto.createdAt,
      linkedTrip: dto.trip == null ? null : toLinkedTrip(dto.trip!),
      tracking: dto.tracking?.toEntity(),
    );
  }

  static LinkedTrip toLinkedTrip(LinkedTripDto dto) {
    return LinkedTrip(
      id: dto.id,
      status: dto.status,
      driverNameEn: dto.driverNameEn,
      driverNameAr: dto.driverNameAr,
      confirmationStatus: dto.confirmationStatus,
      driverShowedUp: dto.driverShowedUp,
    );
  }

  /// Joins API cluster metadata with already-loaded [TripRequest]s.
  static GroupSuggestion? toGroupSuggestion({
    required GroupSuggestionDto dto,
    required Map<String, TripRequest> requestsById,
  }) {
    final members = <TripRequest>[
      for (final id in dto.requestIds)
        if (requestsById[id] != null) requestsById[id]!,
    ]..sort((a, b) => a.requestedDateTime.compareTo(b.requestedDateTime));

    if (members.length < 2) return null;

    return GroupSuggestion(
      clusterId: dto.clusterId,
      requests: members,
      routeLabel: dto.routeLabel,
      earliestDateTime: dto.earliestRequestedAt,
      latestDateTime: dto.latestRequestedAt,
    );
  }
}
