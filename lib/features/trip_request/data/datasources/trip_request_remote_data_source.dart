import 'package:teletech_drivers/features/trip_request/data/models/group_suggestion_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Remote access to trip requests (Laravel API).
abstract interface class TripRequestRemoteDataSource {
  /// POST body is built by the repository (nested `pickup` / `destination`).
  Future<TripRequestDto> createRequest(Map<String, dynamic> body);

  /// Requests of the authenticated user (`/mine`), all pages.
  Future<List<TripRequestDto>> listMine({
    TripRequestStatus? status,
    TripRequestListBucket? bucket,
    bool awaitingConfirmation = false,
  });

  /// `POST /trip-requests/{id}/confirm-trip`.
  Future<TripRequestDto> confirmTrip(
    String id, {
    required bool driverShowedUp,
    String? note,
  });

  /// Company-wide requests, all pages.
  Future<List<TripRequestDto>> listAll({
    TripRequestStatus? status,
    bool? hasTrip,
    Branch? branch,
    TripRequestStage? stage,
  });

  Future<TripRequestDto> getById(String id);

  Future<TripRequestDto> cancel(String id);

  Future<TripRequestDto> approve(String id);

  Future<TripRequestDto> reject(String id, {String? reason});

  Future<List<TripRequestDto>> approveGroup(List<String> requestIds);

  Future<List<GroupSuggestionDto>> groupingSuggestions();
}
