import 'package:equatable/equatable.dart';

/// Confirmed map point with optional resolved address.
class PickedLocation extends Equatable {
  const PickedLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;

  @override
  List<Object?> get props => [lat, lng, address];
}
