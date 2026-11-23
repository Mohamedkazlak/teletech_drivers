import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// Trip summary embedded on a trip request (`trip` block).
class LinkedTrip extends Equatable {
  const LinkedTrip({
    required this.id,
    required this.status,
    this.driverNameEn,
    this.driverNameAr,
    this.confirmationStatus,
    this.driverShowedUp,
  });

  final String id;
  final TripStatus status;
  final String? driverNameEn;
  final String? driverNameAr;
  final TripConfirmationStatus? confirmationStatus;
  final bool? driverShowedUp;

  /// True when the employee still has to file the trip report.
  bool get needsReport =>
      status == TripStatus.completed &&
      confirmationStatus == TripConfirmationStatus.pending;

  /// Arabic name when the UI language is Arabic, otherwise English.
  String? localizedDriverName(String languageCode) {
    if (languageCode == 'ar') {
      final arabic = _nonEmpty(driverNameAr);
      if (arabic != null) return arabic;
    }
    return _nonEmpty(driverNameEn) ?? _nonEmpty(driverNameAr);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  List<Object?> get props => [
    id,
    status,
    driverNameEn,
    driverNameAr,
    confirmationStatus,
    driverShowedUp,
  ];
}
