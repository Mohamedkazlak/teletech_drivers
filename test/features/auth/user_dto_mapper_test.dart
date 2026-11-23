import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  test('maps null name_ar and missing private fields', () {
    final dto = UserDto.fromJson({
      'id': 'u1',
      'name_en': 'Ada',
      'name_ar': null,
      'email': 'ada@test.com',
      'role': 'employee',
      'is_active': true,
      'phone': '0100',
      'branch': 'company_headquarters',
      'must_change_password': true,
      'is_available': false,
    });

    expect(dto.nameAr, isNull);
    expect(dto.nationalId, isNull);

    final user = UserDtoMapper.toEntity(dto);
    expect(user.name, 'Ada');
    expect(user.nameEn, 'Ada');
    expect(user.nameAr, isNull);
    expect(user.role, UserRole.employee);
    expect(user.isAvailable, isFalse);
    expect(user.mustChangePassword, isTrue);
    expect(dto.toJson()['branch'], 'company_headquarters');
  });

  test('maps is_available and defaults to false when absent', () {
    final withValue = UserDto.fromJson({
      'id': 'd1',
      'name_en': 'Driver',
      'email': 'd@test.com',
      'role': 'driver',
      'is_active': true,
      'is_available': true,
    });
    expect(UserDtoMapper.toEntity(withValue).isAvailable, isTrue);

    final missing = UserDto.fromJson({
      'id': 'd2',
      'name_en': 'Driver',
      'email': 'd2@test.com',
      'role': 'driver',
      'is_active': true,
    });
    expect(UserDtoMapper.toEntity(missing).isAvailable, isFalse);
  });

  test('driver summary tolerates missing private fields', () {
    final dto = UserDto.fromJson({
      'id': 'd1',
      'name_en': 'Driver',
      'name_ar': 'سائق',
      'email': 'd@test.com',
      'role': 'driver',
      'is_active': true,
      'phone': null,
      'is_available': true,
      'favorite_place_ids': ['p1'],
      'deleted_at': null,
      'deleted_by': null,
    });

    expect(dto.nationalId, isNull);
    expect(dto.carLicense, isNull);
    expect(dto.personalLicense, isNull);
    expect(dto.favoritePlaceIds, ['p1']);
  });
}
