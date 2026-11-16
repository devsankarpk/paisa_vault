import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_card/emv.dart';

void main() {
  test('parses PAN and expiry from tag 5A and 5F24', () {
    // 70 len { 5A 08 4111111111111111, 5F24 03 301231 }
    final t = parseTlv('70105A0841111111111111115F2403301231');
    final f = extractFindings(t, aid: 'A0000000031010');
    expect(f.panFound, true);
    expect(f.last4, '1111');
    expect(f.luhn, true);
    expect(f.expiryMonthYear, '12/30');
    expect(f.network, 'Visa');
  });

  test('reads track 2 equivalent data when 5A is missing', () {
    // 57 len: PAN D YYMM ... F padding
    final t = parseTlv('700D570B5555555555554444D2905F');
    final f = extractFindings(t, aid: 'A0000000041010');
    expect(f.panFound, true);
    expect(f.last4, '4444');
    expect(f.panSource, '57');
    expect(f.expiryMonthYear, '05/29');
  });

  test('returns nothing when the card gives no number', () {
    final f = extractFindings(parseTlv('6F0A8408A0000005241010'), aid: 'A0000005241010');
    expect(f.panFound, false);
    expect(f.network, 'RuPay');
  });
}
