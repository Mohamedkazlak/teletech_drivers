import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/place/data/mappers/place_dto_mapper.dart';
import 'package:teletech_drivers/features/place/data/models/place_dto.dart';

void main() {
  test('missing created_at maps to null', () {
    final dto = PlaceDto.fromJson({
      'id': 'p1',
      'name_en': 'HQ',
      'name_ar': 'المقر',
      'latitude': 30.0,
      'longitude': 31.0,
      'address': 'Cairo',
      'is_headquarters': true,
      'is_active': true,
    });

    final place = PlaceDtoMapper.toEntity(dto);
    expect(place.id, 'p1');
    expect(place.isHeadquarters, isTrue);
    expect(place.latitude, 30.0);
    expect(dto.createdAt, isNull);
    expect(place.createdAt, isNull);
  });

  test('maps created_at as UTC', () {
    final dto = PlaceDto.fromJson({
      'id': 'p3',
      'name_en': 'HQ',
      'name_ar': 'المقر',
      'latitude': 30.0,
      'longitude': 31.0,
      'is_headquarters': false,
      'is_active': true,
      'created_at': '2026-11-02T10:00:00Z',
    });

    expect(dto.createdAt, DateTime.utc(2026, 11, 2, 10));
    expect(PlaceDtoMapper.toEntity(dto).createdAt, DateTime.utc(2026, 11, 2, 10));
  });

  test('null coordinates stay null', () {
    final dto = PlaceDto.fromJson({
      'id': 'p2',
      'name_en': 'Campus',
      'name_ar': 'حرم',
      'latitude': null,
      'longitude': null,
      'is_headquarters': false,
      'is_active': true,
    });
    expect(dto.latitude, isNull);
    expect(dto.longitude, isNull);
  });
}
