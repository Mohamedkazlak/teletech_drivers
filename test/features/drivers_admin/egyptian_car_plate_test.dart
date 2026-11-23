import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/egyptian_car_plate.dart';

void main() {
  test('canonical plate spaces letters and keeps the number', () {
    expect(EgyptianCarPlate.fromParts('طعب', '9295'), 'ط ع ب 9295');
    expect(EgyptianCarPlate.canonical('ط ع ب 9295'), 'ط ع ب 9295');
    expect(EgyptianCarPlate.canonical('ا ب ١٢٣'), 'أ ب 123');
    expect(
      EgyptianCarPlate.parts('طعب9295'),
      (letters: 'ط ع ب', numbers: '9295'),
    );
  });

  test('rejects a free-text license', () {
    expect(EgyptianCarPlate.canonical('CAR-1'), isNull);
    expect(EgyptianCarPlate.fromParts('', '9295'), isNull);
    expect(EgyptianCarPlate.lettersField('ط ع ب ج'), 'ط ع ب');
    expect(EgyptianCarPlate.numbersField('92951'), '9295');
  });
}
