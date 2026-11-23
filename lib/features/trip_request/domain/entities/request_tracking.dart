import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Server-derived requester lifecycle. The API is the only source of the stage.
enum RequestTrackingStage {
  submitted,
  approved,
  rejected,
  driverAssigned,
  inProgress,
  finished,
  awaitingConfirmation,
  confirmed,
  unconfirmed,
  cancelled;

  static RequestTrackingStage parse(String raw) {
    return switch (raw) {
      'submitted' => submitted,
      'approved' => approved,
      'rejected' => rejected,
      'driver_assigned' => driverAssigned,
      'in_progress' => inProgress,
      'finished' => finished,
      'awaiting_confirmation' => awaitingConfirmation,
      'confirmed' => confirmed,
      'unconfirmed' => unconfirmed,
      'cancelled' => cancelled,
      _ => throw FormatException('Unknown tracking stage: $raw'),
    };
  }

  /// List chip. Finished confirmation states share Completed.
  bool get showsAsCompleted => switch (this) {
    finished || awaitingConfirmation || confirmed || unconfirmed => true,
    _ => false,
  };
}

class RequestTrackingEvent extends Equatable {
  const RequestTrackingEvent({
    required this.stage,
    required this.actorRole,
    this.reachedAt,
  });

  final RequestTrackingStage stage;
  final DateTime? reachedAt;
  final UserRole? actorRole;

  bool get isReached => reachedAt != null;

  @override
  List<Object?> get props => [stage, reachedAt, actorRole];
}

class RequestTrackingDriver extends Equatable {
  const RequestTrackingDriver({this.nameEn, this.nameAr, this.phone});

  final String? nameEn;
  final String? nameAr;
  final String? phone;

  String? localizedName(String languageCode) {
    if (languageCode == 'ar') {
      final arabic = _nonEmpty(nameAr);
      if (arabic != null) return arabic;
    }
    return _nonEmpty(nameEn) ?? _nonEmpty(nameAr);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  List<Object?> get props => [nameEn, nameAr, phone];
}

class RequestTrackingVehicle extends Equatable {
  const RequestTrackingVehicle({required this.carLicense});

  final String carLicense;

  @override
  List<Object?> get props => [carLicense];
}

/// Derived tracking block on a requester's request or trip.
class RequestTracking extends Equatable {
  const RequestTracking({
    required this.stage,
    required this.timeline,
    this.rejectionReason,
    this.driver,
    this.scheduledAt,
    this.vehicle,
  });

  final RequestTrackingStage stage;
  final List<RequestTrackingEvent> timeline;
  final String? rejectionReason;
  final RequestTrackingDriver? driver;
  final DateTime? scheduledAt;
  final RequestTrackingVehicle? vehicle;

  RequestTrackingEvent? eventFor(RequestTrackingStage stage) {
    for (final event in timeline) {
      if (event.stage == stage) return event;
    }
    return null;
  }

  bool get isApproved =>
      eventFor(RequestTrackingStage.approved)?.isReached ?? false;

  bool get isDriverAssigned => driver != null;

  @override
  List<Object?> get props => [
    stage,
    timeline,
    rejectionReason,
    driver,
    scheduledAt,
    vehicle,
  ];
}
