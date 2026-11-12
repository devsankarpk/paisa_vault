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
final _debitOnly = RegExp(
  r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted)\b',
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
    (c) =>
        RegExp(r'(?<!\d)(?<!\d\.)' + RegExp.escape(c) + r'(?!\d|\.\d)')
            .hasMatch(plain),
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
    if (debit && credit) {
      // Both words: the first one describes this account ("debited ... credited to X").
      final d = _debitOnly.firstMatch(low);
      final c = _credit.firstMatch(low)!;
      data['direction'] = (d != null && d.start < c.start) ? 'debit' : 'credit';
    }
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
  } else if (low.contains('neft')) {
    data['channel'] = 'NEFT';
  } else if (low.contains('imps')) {
    data['channel'] = 'IMPS';
  } else if (RegExp(r'\batm\b').hasMatch(low) || low.contains('withdrawn')) {
    data['channel'] = 'ATM';
  }
  final ref = RegExp(
    r'\bref(?:erence)?\.?(?:\s*(?:no|number|id)\.?)?[\s:#-]*(?:upi[\s:-]*)?(\d{6,})',
  ).firstMatch(low);
  if (ref != null) {
    data['reference'] = ref.group(1);
  } else {
    final long = RegExp(r'(?<!\d)\d{12}(?!\d)').firstMatch(low);
    if (long != null) data['reference'] = long.group(0);
  }

  final date = _parseDate(sms);
  if (date != null) data['date'] = date;
  if (data['last4'] != null) {
    final digits = data['last4'].toString().replaceAll(RegExp(r'\D'), '');
    data['last4'] = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : null;
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
    data['reference'] = RegExp(r'\d{6,}')
        .firstMatch(data['reference'].toString())
        ?.group(0);
  }
  if (data['merchant'] != null) {
    data['merchant'] = data['merchant']
        .toString()
        .replaceFirst(RegExp(r'^(vpa|upi)[\s:-]+', caseSensitive: false), '')
        .trim();
  }
  return data;
}

final _amountRs = RegExp(
  r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d+)?)',
  caseSensitive: false,
);
final _amountBy = RegExp(r'\b(?:by|of)\s+([\d,]+\.\d+)', caseSensitive: false);
final _last4 = RegExp(
  r'(?:a/c|acct|card|ending)(?:\s+no\.?)?\s*[*x]*(\d{4,})',
  caseSensitive: false,
);

/// Fields that plain rules can read from the SMS, so the model does not have to
/// generate them. The model is then asked only for merchant and category.
Map<String, dynamic> ruleFields(String sms) {
  final data = <String, dynamic>{'is_transaction': false};
  final m = _amountRs.firstMatch(sms) ?? _amountBy.firstMatch(sms);
  if (m != null)
    data['amount'] = double.tryParse(m.group(1)!.replaceAll(',', ''));
  data['last4'] = _last4.firstMatch(sms)?.group(1);
  final low = sms.toLowerCase();
  data['account_type'] = low.contains('credit card')
      ? 'credit_card'
      : low.contains('card')
      ? 'debit_card'
      : 'savings_account';
  return data;
}

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

String? _fmt(int y, int m, int d) {
  if (d < 1 || d > 31 || m < 1 || m > 12) return null;
  if (y < 100) y += 2000;
  return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
}

/// Indian SMS dates: 05/11/26, 21-10-26, 2026-10-18, 12Oct26, 02-Nov-26 (day first).
String? _parseDate(String sms) {
  var m = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(sms);
  if (m != null) {
    return _fmt(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
  m = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})\b').firstMatch(sms);
  if (m != null) {
    return _fmt(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  }
  m = RegExp(r'\b(\d{1,2})[- ]?([A-Za-z]{3})[a-z]*[- ]?(\d{2}|\d{4})\b')
      .firstMatch(sms);
  if (m != null) {
    final mon = _months[m.group(2)!.toLowerCase()];
    if (mon != null) {
      return _fmt(int.parse(m.group(3)!), mon, int.parse(m.group(1)!));
    }
  }
  return null;
}

final _merchantPatterns = <RegExp>[
  RegExp(r'UPI-([^-]+)-\S+@', caseSensitive: false),
  RegExp(r'UPI/P2[MP]/\d+/(.+?)\s+(?:not|if)\b', caseSensitive: false),
  RegExp(r'NEFT/([^/)]+)/', caseSensitive: false),
  RegExp(r'NEFT from (.+?)\.', caseSensitive: false),
  RegExp(r'trf to (.+?)\s+ref', caseSensitive: false),
  RegExp(r'\bto (?!VPA|A/c|Acct)(.+?)\s+on\s+\d', caseSensitive: false),
  RegExp(r'\bat (.+?)(?:\s+on\s+\d|\.)', caseSensitive: false),
];

/// Merchant from the usual bank SMS phrasings. Null when no pattern fits, then the model decides.
String? ruleMerchant(String sms) {
  for (final p in _merchantPatterns) {
    final v = p.firstMatch(sms)?.group(1)?.trim();
    if (v != null &&
        v.isNotEmpty &&
        !RegExp(
          r'\b(atm|a/c|acct|card|bank|your)\b',
          caseSensitive: false,
        ).hasMatch(v)) {
      return v;
    }
  }
  return null;
}

bool looksLikeBank(String? name) {
  if (name == null) return false;
  final low = name.toLowerCase();
  return low.contains('bank') ||
      bankNames.values.any((p) => RegExp(p).hasMatch(low));
}
