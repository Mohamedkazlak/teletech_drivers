/// Sample JSON shapes mirroring `TripRequestResource`, `TripResource`,
/// `TripPassengerResource`, `GroupSuggestionResource` and friends.
abstract final class ApiFixtures {
  static Map<String, dynamic> approvedPlace({
    String id = 'place-hq',
    String name = 'HQ',
  }) {
    return {
      'place_id': id,
      'name': name,
      'lat': 30.05,
      'lng': 31.23,
      'address': 'Cairo',
    };
  }

  static Map<String, dynamic> customPlace({
    String id = 'custom:abc',
    String name = 'Pinned spot',
  }) {
    return {
      'place_id': id,
      'name': name,
      'lat': 30.1,
      'lng': 31.3,
      'address': 'Somewhere',
    };
  }

  static Map<String, dynamic> tripRequest({
    String id = 'req-1',
    String employeeId = 'emp-1',
    String status = 'pending',
    String? tripId,
    Map<String, dynamic>? pickup,
    Map<String, dynamic>? destination,
    String requestedAt = '2026-11-03T08:00:00Z',
    String createdAt = '2026-11-02T10:00:00Z',
  }) {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name_en': 'Sara Ali',
      'employee_name_ar': 'سارة علي',
      'employee_phone': '+201000000000',
      'employee_branch': 'company_headquarters',
      'requester_role': 'employee',
      'pickup': pickup ?? approvedPlace(),
      'destination':
          destination ?? approvedPlace(id: 'place-airport', name: 'Airport'),
      'requested_at': requestedAt,
      'notes': 'Two bags',
      'status': status,
      'trip_id': tripId,
      'rejection_reason': null,
      'handled_by': null,
      'handled_at': null,
      'auto_approved': false,
      'suggested_group_id': null,
      'created_at': createdAt,
    };
  }

  static Map<String, dynamic> groupSuggestion({
    String clusterId = 'cluster-1',
    List<String> requestIds = const ['req-1', 'req-2'],
  }) {
    return {
      'cluster_id': clusterId,
      'request_ids': requestIds,
      'destination_label': 'Airport',
      'route_label': 'HQ → Airport',
      'date': '2026-11-03',
      'earliest_requested_at': '2026-11-03T08:00:00Z',
      'latest_requested_at': '2026-11-03T09:00:00Z',
    };
  }

  static Map<String, dynamic> user({
    String id = 'drv-1',
    String role = 'driver',
  }) {
    return {
      'id': id,
      'name_en': 'Omar Driver',
      'name_ar': 'عمر',
      'email': 'omar@example.test',
      'role': role,
      'is_active': true,
      'phone': '+201111111111',
      'branch': 'new_headquarters',
      'is_available': true,
      'favorite_place_ids': ['place-airport'],
      'national_id': '1234567890',
      'car_license': 'CAR-1',
      'personal_license': 'PER-1',
    };
  }

  static Map<String, dynamic> passenger({
    String employeeId = 'emp-1',
    String requestId = 'req-1',
    String? nameEn = 'Sara Ali',
    String? nameAr = 'سارة علي',
    String? branch = 'company_headquarters',
  }) {
    return {
      'employee_id': employeeId,
      'name_en': nameEn,
      'name_ar': nameAr,
      'phone': '+201000000000',
      'branch': branch,
      'request_id': requestId,
      'pickup': approvedPlace(),
      'destination': approvedPlace(id: 'place-airport', name: 'Airport'),
    };
  }

  /// Requester object (`id`, names, phone, branch) projected from a passenger row.
  static Map<String, dynamic> requesterFromPassenger(
    Map<String, dynamic> passenger,
  ) {
    return {
      'id': passenger['employee_id'],
      'name_en': passenger['name_en'],
      'name_ar': passenger['name_ar'],
      'phone': passenger['phone'],
      'branch': passenger['branch'],
    };
  }

  /// Full `TripResource` (detail) including route and start coordinates.
  static Map<String, dynamic> trip({
    String id = 'trip-1',
    String status = 'assigned',
    String? driverId = 'drv-1',
    List<Map<String, dynamic>>? passengers,
  }) {
    final rows = passengers ?? [passenger()];
    return {
      'id': id,
      'driver_id': driverId,
      'driver': driverId == null ? null : user(id: driverId),
      'scheduled_at': '2026-11-03T08:00:00Z',
      'status': status,
      'created_by': 'admin-1',
      'pickup_summary': 'HQ',
      'destination_summary': 'Airport',
      'going_started_at': '2026-11-03T08:05:00Z',
      'going_ended_at': '2026-11-03T08:45:00Z',
      'return_started_at': '2026-11-03T09:15:00Z',
      'finished_at': '2026-11-03T09:55:00Z',
      'going_distance_m': 12500.5,
      'return_distance_m': 13000,
      'total_distance_m': 25500.5,
      'passengers': rows,
      'requester': rows.isEmpty ? null : requesterFromPassenger(rows.first),
      'requesters': [for (final row in rows) requesterFromPassenger(row)],
      'passenger_count': rows.length,
      'created_at': '2026-11-02T10:00:00Z',
      'start_lat': 30.01,
      'start_lng': 31.02,
      'going_route': '_p~iF~ps|U_ulLnnqC',
      'return_route': '_mqNvxq`@',
    };
  }

  /// `TripSummaryResource` (list): no route / start fields.
  static Map<String, dynamic> tripSummary({
    String id = 'trip-2',
    String status = 'unassigned',
  }) {
    final rows = [passenger()];
    return {
      'id': id,
      'driver_id': null,
      'driver': null,
      'scheduled_at': '2026-11-03T10:00:00Z',
      'status': status,
      'created_by': 'admin-1',
      'pickup_summary': 'HQ',
      'destination_summary': 'Airport',
      'passengers': rows,
      'requester': requesterFromPassenger(rows.first),
      'requesters': [for (final row in rows) requesterFromPassenger(row)],
      'passenger_count': rows.length,
      'created_at': '2026-11-02T11:00:00Z',
    };
  }

  static Map<String, dynamic> tripReport({String status = 'completed'}) {
    return {
      'status': status,
      'is_in_progress': false,
      'start': '2026-11-03T08:05:00Z',
      'finish': '2026-11-03T09:55:00Z',
      'going_duration_seconds': 2400,
      'waiting_duration_seconds': 1800,
      'return_duration_seconds': 2400,
      'total_duration_seconds': 6600,
      'going_distance_km': 12.5,
      'return_distance_km': 13.0,
      'total_distance_km': 25.5,
      'going_route': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'return_route': '_mqNvxq`@',
    };
  }

  static Map<String, dynamic> driverRecommendation({
    String driverId = 'drv-1',
    int tier = 1,
    bool hasFavoriteMatch = true,
    bool hasConflict = false,
    bool isUnavailable = false,
    bool needsConfirmation = false,
    bool isOnActiveTrip = false,
    int? tripsThisWeek = 3,
  }) {
    return {
      'driver': user(id: driverId),
      'tier': tier,
      'has_favorite_match': hasFavoriteMatch,
      'has_conflict': hasConflict,
      'is_unavailable': isUnavailable,
      'needs_confirmation': needsConfirmation,
      'is_on_active_trip': isOnActiveTrip,
      'trips_this_week': tripsThisWeek,
    };
  }
}
