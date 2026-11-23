import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';

void main() {
  test('trip request lists poll every 15 seconds', () {
    expect(PollingIntervals.tripRequestLists, const Duration(seconds: 15));
  });

  test('trip lists poll every 15 seconds', () {
    expect(PollingIntervals.tripLists, const Duration(seconds: 15));
  });

  test('trip details poll every 15 seconds', () {
    expect(PollingIntervals.tripDetails, const Duration(seconds: 15));
  });

  test('fallback polling stays between 15 and 30 seconds', () {
    const windowStart = Duration(seconds: 15);
    const windowEnd = Duration(seconds: 30);
    expect(PollingIntervals.tripDetails, greaterThanOrEqualTo(windowStart));
    expect(PollingIntervals.tripDetails, lessThanOrEqualTo(windowEnd));
    expect(PollingIntervals.tripLists, greaterThanOrEqualTo(windowStart));
    expect(PollingIntervals.liveMap, lessThanOrEqualTo(windowEnd));
  });
}
