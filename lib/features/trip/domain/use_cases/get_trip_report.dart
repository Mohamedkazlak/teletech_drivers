import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class GetTripReportUseCase {
  const GetTripReportUseCase(this._repository);

  final TripRepository _repository;

  Future<TripReport> call(String tripId) => _repository.getTripReport(tripId);
}
