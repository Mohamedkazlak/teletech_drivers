import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_state.dart';

/// Ordered progress timeline for a trip request (and optional linked trip).
class RequestProgress extends Equatable {
  const RequestProgress({required this.steps});

  final List<RequestProgressStep> steps;

  /// The step marked [RequestProgressStepState.current], if any.
  RequestProgressStep? get currentStep {
    for (final step in steps) {
      if (step.state == RequestProgressStepState.current) return step;
    }
    return null;
  }

  /// The step marked [RequestProgressStepState.failed], if any.
  RequestProgressStep? get failedStep {
    for (final step in steps) {
      if (step.state == RequestProgressStepState.failed) return step;
    }
    return null;
  }

  /// Fraction of steps completed (done / total), ignoring failed terminal lists.
  double get fractionComplete {
    if (steps.isEmpty) return 0;
    final doneCount = steps
        .where((step) => step.state == RequestProgressStepState.done)
        .length;
    return doneCount / steps.length;
  }

  @override
  List<Object?> get props => [steps];
}
