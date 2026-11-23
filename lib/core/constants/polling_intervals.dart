/// Polling cadence for StreamProviders backed by the Laravel API.
abstract final class PollingIntervals {
  static const places = Duration(seconds: 30);
  static const drivers = Duration(seconds: 20);
  static const employees = Duration(seconds: 20);
  static const users = Duration(seconds: 20);
  static const tripRequestLists = Duration(seconds: 15);
  static const tripLists = Duration(seconds: 15);
  static const tripDetails = Duration(seconds: 15);
  static const availability = Duration(seconds: 15);
  static const liveMap = Duration(seconds: 20);
  static const notifications = Duration(seconds: 15);
  static const sessionResumeDebounce = Duration(milliseconds: 300);
}
