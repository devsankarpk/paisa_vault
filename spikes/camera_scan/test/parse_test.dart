import 'package:camera_scan/card_parse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a spaced number and expiry', () {
    final f = parseCardText([
      'BANK',
      '4111 1111 1111 1111',
      'VALID THRU',
      '12/30',
      'A B SHARMA',
    ]);
    expect(f.numberFound, true);
    expect(f.last4, '1111');
    expect(f.luhn, true);
    expect(f.expiry, '12/30');
  });
  test('joins four-digit blocks', () {
    final f = parseCardText(['5555', '5555', '5555', '4444', '05/29']);
    expect(f.last4, '4444');
    expect(f.expiry, '05/29');
  });
  test('ignores phone-like numbers and dates', () {
    final f = parseCardText(['1800 202 6161', '13/45']);
    expect(f.numberFound, false);
    expect(f.expiryFound, false);
  });
  test('prefers the Luhn-valid candidate', () {
    final f = parseCardText(['1234 5678 9012 3456', '4111 1111 1111 1111']);
    expect(f.last4, '1111');
  });

  test('joins two lines of 8 digits', () {
    final f = parseCardText(['BANK', '41111111', '11111111', '12/30']);
    expect(f.last4, '1111');
    expect(f.length, 16);
    expect(f.luhn, true);
  });
  test('joins four lines of 4 digits with other text around', () {
    final f = parseCardText([
      'VISA',
      '4111',
      '1111',
      '1111',
      '1111',
      'VALID THRU',
      '12/30',
    ]);
    expect(f.last4, '1111');
    expect(f.luhn, true);
  });
  test('does not join across a text line', () {
    final f = parseCardText(['4111 1111', 'NAME', '1111 1111']);
    expect(f.numberFound, false);
  });

  test(
    'repairs digits read as look-alike letters when the checksum passes',
    () {
      final f = parseCardText(['4III 1111', '1III 1III', 'I2/3O']);
      expect(f.numberFound, true);
      expect(f.last4, '1111');
      expect(f.luhn, true);
      expect(f.expiry, '12/30');
    },
  );
  test('does not turn ordinary words into a number', () {
    final f = parseCardText(['AXIS BANK', 'SAVINGS CARD']);
    expect(f.numberFound, false);
  });

  test('accepts a dot read in place of a space', () {
    final f = parseCardText(['4111 1111.1111 1111', '12/30']);
    expect(f.last4, '1111');
    expect(f.luhn, true);
  });
  test('a number with a dropped digit is not confirmed', () {
    final f = parseCardText(['4111 1111.1111 111']);
    expect(f.luhn, false);
  });

  test('ignores stray bars around four-digit blocks on separate lines', () {
    final f = parseCardText([
      '(VALID THRU)',
      '4111',
      '|1111',
      '|1111',
      '|1111',
      '12/30',
    ]);
    expect(f.last4, '1111');
    expect(f.luhn, true);
    expect(f.expiry, '12/30');
  });
}
