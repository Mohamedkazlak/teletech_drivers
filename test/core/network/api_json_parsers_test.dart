import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';

void main() {
  test('optionalDouble reads a string, a number, and null', () {
    expect(ApiJsonParsers.optionalDouble('30.0444'), 30.0444);
    expect(ApiJsonParsers.optionalDouble(31.2), 31.2);
    expect(ApiJsonParsers.optionalDouble(31), 31);
    expect(ApiJsonParsers.optionalDouble(null), isNull);
    expect(ApiJsonParsers.optionalDouble(''), isNull);
    expect(ApiJsonParsers.optionalDouble('north'), isNull);
  });
}
