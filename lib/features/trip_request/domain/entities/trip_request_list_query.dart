import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Server filters for `GET /trip-requests`.
///
/// Null [branch] omits the query param (every branch).
class TripRequestListQuery extends Equatable {
  const TripRequestListQuery({this.status, this.branch, this.stage});

  final TripRequestStatus? status;
  final Branch? branch;
  final TripRequestStage? stage;

  @override
  List<Object?> get props => [status, branch, stage];
}
