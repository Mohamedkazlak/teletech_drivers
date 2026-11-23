import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/data/mappers/driver_dto_mapper.dart';

void main() {
  test('full driver keeps private fields', () {
    final dto = UserDto.fromJson({
      'id': 'd1',
      'name_en': 'Driver',
      'name_ar': 'سائق',
      'email': 'd@test.com',
      'role': 'driver',
      'is_active': true,
      'phone': '0100',
      'is_available': true,
      'national_id': '12345678901234',
      'car_license': 'car',
      'personal_license': 'personal',
      'favorite_place_ids': ['p1'],
    });

    final profile = DriverDtoMapper.toProfile(dto);
    expect(profile.isAvailable, isTrue);
    expect(profile.nationalId, '12345678901234');
    expect(profile.carLicense, 'car');
    expect(profile.personalLicense, 'personal');
  });

  test('summary driver uses empty private fields', () {
    final dto = UserDto.fromJson({
      'id': 'd2',
      'name_en': 'Driver',
      'name_ar': null,
      'email': 'd2@test.com',
      'role': 'driver',
      'is_active': true,
      'is_available': false,
      'favorite_place_ids': <String>[],
    });

    final profile = DriverDtoMapper.toProfile(dto);
    expect(profile.nameAr, 'Driver');
    expect(profile.nationalId, '');
    expect(profile.carLicense, '');
    expect(profile.personalLicense, '');
    expect(profile.isAvailable, isFalse);
  });
}
