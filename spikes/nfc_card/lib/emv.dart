// Minimal EMV contactless reader logic for the NFC spike.
// Works on hex strings. It never keeps the full card number: callers get
// only last 4 digits, length, and yes/no flags.

class Tlv {
  Tlv(this.tag, this.value, [this.children = const []]);
  final String tag; // hex, upper case
  final String value; // hex
  final List<Tlv> children;
}

/// Tags that hold other TLVs (constructed): first byte bit 6 set.
bool _constructed(String tag) => (int.parse(tag.substring(0, 2), radix: 16) & 0x20) != 0;

List<Tlv> parseTlv(String hex) {
  final out = <Tlv>[];
  var i = 0;
  final n = hex.length;
  while (i + 4 <= n) {
    var tag = hex.substring(i, i + 2);
    i += 2;
    if ((int.parse(tag, radix: 16) & 0x1F) == 0x1F) {
      while (i + 2 <= n) {
        final b = hex.substring(i, i + 2);
        tag += b;
        i += 2;
        if ((int.parse(b, radix: 16) & 0x80) == 0) break;
      }
    }
    if (i + 2 > n) break;
    var len = int.parse(hex.substring(i, i + 2), radix: 16);
    i += 2;
    if (len & 0x80 != 0) {
      final k = len & 0x7F;
      if (i + 2 * k > n) break;
      len = int.parse(hex.substring(i, i + 2 * k), radix: 16);
      i += 2 * k;
    }
    if (i + 2 * len > n) break;
    final v = hex.substring(i, i + 2 * len);
    i += 2 * len;
    tag = tag.toUpperCase();
    out.add(Tlv(tag, v.toUpperCase(), _constructed(tag) ? parseTlv(v) : const []));
  }
  return out;
}

Iterable<Tlv> walk(List<Tlv> list) sync* {
  for (final t in list) {
    yield t;
    yield* walk(t.children);
  }
}

String? firstValue(List<Tlv> list, String tag) {
  for (final t in walk(list)) {
    if (t.tag == tag) return t.value;
  }
  return null;
}

List<String> allValues(List<Tlv> list, String tag) =>
    [for (final t in walk(list)) if (t.tag == tag) t.value];

bool luhnOk(String digits) {
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var d = int.parse(digits[i]);
    if (alt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    alt = !alt;
  }
  return digits.isNotEmpty && sum % 10 == 0;
}

String networkFromAid(String aid) {
  final a = aid.toUpperCase();
  if (a.startsWith('A000000003')) return 'Visa';
  if (a.startsWith('A000000004') || a.startsWith('A000000005')) return 'Mastercard';
  if (a.startsWith('A000000524')) return 'RuPay';
  if (a.startsWith('A000000025')) return 'Amex';
  if (a.startsWith('A000000065')) return 'JCB';
  if (a.startsWith('A000000152')) return 'Discover';
  return 'Other';
}

/// Result without the full card number.
class CardFindings {
  CardFindings({
    this.network = 'unknown',
    this.aid = '',
    this.panFound = false,
    this.panSource = '',
    this.panLength = 0,
    this.last4 = '',
    this.luhn = false,
    this.expiryFound = false,
    this.expiryMonthYear = '',
    this.holderFound = false,
    this.error = '',
  });
  String network;
  String aid;
  bool panFound;
  String panSource; // 5A, 57 or 9F6B
  int panLength;
  String last4;
  bool luhn;
  bool expiryFound;
  String expiryMonthYear; // MM/YY
  bool holderFound;
  String error;
}

/// Pulls card data from all collected response TLVs. Pure function: testable.
CardFindings extractFindings(List<Tlv> all, {String aid = ''}) {
  final f = CardFindings(aid: aid, network: aid.isEmpty ? 'unknown' : networkFromAid(aid));
  String? pan;
  final t5a = firstValue(all, '5A');
  if (t5a != null) {
    pan = t5a.replaceAll(RegExp(r'F+$'), '');
    f.panSource = '5A';
  }
  String? exp = firstValue(all, '5F24'); // YYMMDD
  for (final tag in ['57', '9F6B']) {
    final t2 = firstValue(all, tag);
    if (t2 == null) continue;
    final d = t2.indexOf('D');
    if (d > 0) {
      if (pan == null) {
        pan = t2.substring(0, d).replaceAll(RegExp(r'F+$'), '');
        f.panSource = tag;
      }
      if (exp == null && t2.length >= d + 5) {
        exp = '${t2.substring(d + 1, d + 5)}00'; // YYMM
      }
    }
  }
  if (pan != null && RegExp(r'^\d{12,19}$').hasMatch(pan)) {
    f.panFound = true;
    f.panLength = pan.length;
    f.last4 = pan.substring(pan.length - 4);
    f.luhn = luhnOk(pan);
  }
  if (exp != null && exp.length >= 4 && RegExp(r'^\d+$').hasMatch(exp.substring(0, 4))) {
    f.expiryFound = true;
    f.expiryMonthYear = '${exp.substring(2, 4)}/${exp.substring(0, 2)}';
  }
  f.holderFound = firstValue(all, '5F20') != null || firstValue(all, '9F0B') != null;
  return f;
}
