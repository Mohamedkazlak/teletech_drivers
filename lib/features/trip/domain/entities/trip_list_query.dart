import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_lifecycle.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_stage.dart';

/// Server filters for `GET /trips`. Null [branch] means every branch.
class TripListQuery extends Equatable {
  const TripListQuery({this.stage, this.branch, this.lifecycle});

  final TripStage? stage;
  final Branch? branch;
  final TripLifecycle? lifecycle;

  @override
  List<Object?> get props => [stage, branch, lifecycle];
}
