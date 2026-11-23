import 'package:equatable/equatable.dart';

/// A broadcast from the API. Payload stays limited to ids, status, and a map fix.
class RealtimeEvent extends Equatable {
  const RealtimeEvent({
    required this.name,
    required this.id,
    required this.status,
    this.tripId,
    this.lat,
    this.lng,
  });

  final String name;
  final String id;
  final String status;
  final String? tripId;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [name, id, status, tripId, lat, lng];
}
