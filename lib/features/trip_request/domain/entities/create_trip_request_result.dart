import 'package:equatable/equatable.dart';

/// Outcome of creating a trip request (optional trip for Drivers Admin).
class CreateTripRequestResult extends Equatable {
  const CreateTripRequestResult({required this.requestId, this.tripId});

  final String requestId;

  /// Set when Drivers Admin auto-creates an unassigned trip after the request.
  final String? tripId;

  @override
  List<Object?> get props => [requestId, tripId];
}
