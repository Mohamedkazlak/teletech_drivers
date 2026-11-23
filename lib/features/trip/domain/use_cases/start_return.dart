import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class StartReturnUseCase {
  const StartReturnUseCase(this._repository);

  final TripRepository _repository;

  Future<void> call(String tripId) => _repository.startReturn(tripId);
}
