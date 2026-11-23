import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_id.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_state.dart';

/// One step in [RequestProgress], with optional timestamp / failure reason.
class RequestProgressStep extends Equatable {
  const RequestProgressStep({
    required this.id,
    required this.state,
    this.at,
    this.failureReason,
  });

  final RequestProgressStepId id;
  final RequestProgressStepState state;
  final DateTime? at;
  final String? failureReason;

  @override
  List<Object?> get props => [id, state, at, failureReason];
}
