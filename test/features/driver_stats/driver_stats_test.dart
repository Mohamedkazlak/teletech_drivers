import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teletech_drivers/features/driver_stats/data/models/driver_stats_dto.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/stats_chart_label.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('chart labels follow the period', () {
    expect(
      statsChartLabel(
        period: 'week',
        bucketLabel: '2026-11-08',
        localeName: 'en',
      ),
      'Sun',
    );
    expect(
      statsChartLabel(
        period: 'month',
        bucketLabel: '2026-11-08',
        localeName: 'en',
      ),
      '8',
    );
    expect(
      statsChartLabel(
        period: 'year',
        bucketLabel: '2026-11',
        localeName: 'en',
      ),
      'Nov',
    );
    expect(
      statsChartLabel(period: 'all', bucketLabel: '2026', localeName: 'en'),
      '2026',
    );
  });

  test('parses a stats resource', () {
    final dto = DriverStatsDto.fromJson({
      'period': 'week',
      'from': '2026-11-07T00:00:00Z',
      'to': '2026-11-14T00:00:00Z',
      'trips': 2,
      'total_seconds': 5400,
      'total_km': 12.5,
      'breakdown': [
        {
          'label': '2026-11-08',
          'from': '2026-11-08T00:00:00Z',
          'to': '2026-11-09T00:00:00Z',
          'trips': 2,
          'total_seconds': 5400,
          'total_km': 12.5,
        },
      ],
    });

    expect(dto.trips, 2);
    expect(dto.totalSeconds, 5400);
    expect(dto.totalKm, 12.5);
    expect(dto.breakdown.single.label, '2026-11-08');
  });
}
