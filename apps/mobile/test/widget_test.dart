import 'package:admin_market/src/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseNum', () {
    test('parses numeric strings and passes through nums', () {
      expect(parseNum('1250000'), 1250000);
      expect(parseNum('99.5'), 99.5);
      expect(parseNum(42), 42);
      expect(parseNum(null), 0);
      expect(parseNum('not-a-number'), 0);
    });
  });
}
