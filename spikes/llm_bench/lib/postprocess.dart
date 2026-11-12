// Dart port of the rule fixes in tools/llm_console/sms_extract.py (keep the two in step).
// Rules win over the model: they fix mistakes small models make on Indian bank SMS.

const bankNames = <String, String>{
  'HDFC': r'hdfc',
  'SBI': r'\bsbi\b|state bank',
  'ICICI': r'icici',
  'AXIS': r'axis',
  'YES': r'yes\s*bank',
};

final _debit = RegExp(
  r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted|payment of)\b',
);
final _credit = RegExp(r'\b(credited|received|deposited|refund(?:ed)?)\b');
final _failed = RegExp(r'\b(failed|declined|unsuccessful)\b');

/// Safety check from the spec: the amount the model returns must literally appear in the SMS.
bool amountInSms(num? amount, String sms) {
  if (amount == null) return false;
  final plain = sms.replaceAll(',', '');
  final candidates = <String>{
    amount.toStringAsFixed(2),
    if (amount == amount.truncate()) amount.truncate().toString(),
    amount.toString(),
  };
  return candidates.any(
    (c) => RegExp(
      r'(?<!\d)(?<!\d\.)' + RegExp.escape(c) + r'(?!\d|\.\d)',
    ).hasMatch(plain),
  );
}

Map<String, dynamic> postprocess(Map<String, dynamic> data, String sms) {
  final low = sms.toLowerCase();
  final debit = _debit.hasMatch(low);
  final credit = _credit.hasMatch(low);
  // No money moved: OTPs, promos, balance alerts and failed attempts.
  if (!(debit || credit) || _failed.hasMatch(low)) {
    data['is_transaction'] = false;
    return data;
  }
  if (data['amount'] != null) {
    data['is_transaction'] = true;
    if (debit && !credit) data['direction'] = 'debit';
    if (credit && !debit) data['direction'] = 'credit';
  }
  // UPI handles like anita@okhdfcbank name the other party's bank, so ignore them.
  final text = low.replaceAll(RegExp(r'\S*@\S*'), ' ');
  int? best;
  String? bestBank;
  bankNames.forEach((name, pattern) {
    final m = RegExp(pattern).firstMatch(text);
    if (m != null && (best == null || m.start < best!)) {
      best = m.start;
      bestBank = name;
    }
  });
  if (bestBank != null) data['bank'] = bestBank;

  if (RegExp(r'\bupi\b|\bvpa\b|\w@\w').hasMatch(low)) {
    data['channel'] = 'UPI';
  }
  final ref = RegExp(
    r'\bref(?:erence)?\.?(?:\s*(?:no|number|id)\.?)?[\s:#-]*(?:upi[\s:-]*)?(\d{6,})',
  ).firstMatch(low);
  if (ref != null) data['reference'] = ref.group(1);

  final d = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})\b').firstMatch(sms);
  if (d != null) {
    // Indian SMS dates are day first.
    final day = int.parse(d.group(1)!);
    final mon = int.parse(d.group(2)!);
    var yr = int.parse(d.group(3)!);
    if (yr < 100) yr += 2000;
    if (day >= 1 && day <= 31 && mon >= 1 && mon <= 12) {
      data['date'] =
          '${yr.toString().padLeft(4, '0')}-${mon.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }
  }
  if (data['last4'] != null) {
    final digits = data['last4'].toString().replaceAll(RegExp(r'\D'), '');
    data['last4'] =
        digits.length >= 4 ? digits.substring(digits.length - 4) : null;
  }
  final handle = RegExp(r'([\w.\-]+)@(\w+)').firstMatch(sms);
  final merchant = (data['merchant'] ?? '').toString().toLowerCase();
  if (handle != null &&
      (merchant.isEmpty ||
          merchant == 'vpa' ||
          merchant == 'upi' ||
          merchant == handle.group(2)!.toLowerCase())) {
    data['merchant'] = handle.group(1);
  }
  if (data['reference'] != null) {
    data['reference'] =
        RegExp(r'\d{6,}').firstMatch(data['reference'].toString())?.group(0);
  }
  if (data['merchant'] != null) {
    data['merchant'] = data['merchant']
        .toString()
        .replaceFirst(RegExp(r'^(vpa|upi)[\s:-]+', caseSensitive: false), '')
        .trim();
  }
  return data;
}
