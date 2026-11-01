import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_fields.dart';

void main() {
  for (final value in [
    '2026-10-25T24:00:00Z',
    '2026-10-25T08:60:00Z',
    '2026-10-25T08:00:60Z',
    '2026-10-25T08:00:00+02:99',
    '2026-10-25T08:00:00+24:00',
    '2026-02-30T08:00:00Z',
    '2026-10-25'
  ]) {
    test('audit timestamp refuses normalized invalid input $value', () {
      expect(() => iepTimestamp(value), throwsFormatException);
    });
  }
  test('existing ISO and SQL timestamps retain their supported representations',
      () {
    expect(iepTimestamp('2026-10-25T08:00:00Z').isUtc, isTrue);
    expect(iepTimestamp('2026-10-25T10:00:00+02:00'),
        iepTimestamp('2026-10-25T08:00:00Z'));
    expect(iepTimestamp('2026-10-25 08:00:00').hour, 8);
    expect(iepTimestamp('2026-10-25T08:00:00.123456Z').microsecond, 456);
  });
}
