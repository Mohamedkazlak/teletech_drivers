import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_role_mapper.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  test('parses company_admin and drivers_admin API roles', () {
    final companyAdmin = UserDto.fromJson({
      'id': 'uid-1',
      'name_en': 'Admin',
      'email': 'a@test.com',
      'role': 'company_admin',
      'is_active': true,
      'is_available': false,
    });
    expect(companyAdmin.role, UserRole.companyAdmin);
    expect(UserRoleMapper.toApi(companyAdmin.role), 'company_admin');

    final driversAdmin = UserDto.fromJson({
      'id': 'uid-2',
      'name_en': 'Drivers',
      'email': 'd@test.com',
      'role': 'drivers_admin',
      'is_active': true,
      'is_available': false,
    });
    expect(driversAdmin.role, UserRole.driversAdmin);
  });

  test('rejects unknown role strings', () {
    expect(
      () => UserDto.fromJson({
        'id': 'uid-1',
        'name_en': 'X',
        'email': 'x@test.com',
        'role': 'superuser',
        'is_active': true,
      }),
      throwsFormatException,
    );
  });
}
