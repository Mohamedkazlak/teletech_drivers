import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';

/// One page of `GET /trips/created-by-me`.
class TripPage extends Equatable {
  const TripPage({
    required this.trips,
    required this.currentPage,
    required this.lastPage,
  });

  final List<Trip> trips;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  @override
  List<Object?> get props => [trips, currentPage, lastPage];
}
