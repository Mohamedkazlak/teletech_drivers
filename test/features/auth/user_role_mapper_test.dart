import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_role_mapper.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  test('maps every API role value both ways', () {
    const pairs = <(String, UserRole)>[
      ('admin', UserRole.admin),
      ('company_admin', UserRole.companyAdmin),
      ('drivers_admin', UserRole.driversAdmin),
      ('driver', UserRole.driver),
      ('employee', UserRole.employee),
    ];

    for (final (api, role) in pairs) {
      expect(UserRoleMapper.fromApi(api), role);
      expect(UserRoleMapper.toApi(role), api);
    }
  });

  test('rejects unknown role', () {
    expect(() => UserRoleMapper.fromApi('nope'), throwsFormatException);
  });
}
