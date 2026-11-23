/// Marker state from `GET /live-map` (`state`).
enum LiveMapState {
  onTrip('on_trip'),
  available('available'),
  unavailable('unavailable');

  const LiveMapState(this.apiValue);

  final String apiValue;

  static LiveMapState? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final state in LiveMapState.values) {
      if (state.apiValue == value) return state;
    }
    return null;
  }
}
