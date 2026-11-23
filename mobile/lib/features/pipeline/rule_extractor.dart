import '../../core/db/tables.dart';

/// Fields plain rules can read from a bank SMS. Rules win over the model: they are exact and
/// instant, and small models make mistakes on Indian bank SMS (see ADR 0001).
class RuleFields {
  const RuleFields({
    required this.amountPaise,
    required this.direction,
    required this.bank,
    required this.accountKind,
    required this.last4,
    required this.channel,
    required this.reference,
    required this.date,
    required this.merchant,
  });

  /// Always positive. [direction] gives the sign.
  final int? amountPaise;
  final Direction? direction;

  /// Short bank code such as HDFC or SBI, or null when the text does not say.
  final String? bank;
  final AccountKind accountKind;
  final String? last4;

  /// UPI, NEFT, IMPS, ATM, or null when the rules cannot tell (the model may suggest one).
  final String? channel;
  final String? reference;
  final DateTime? date;

  /// Set only when a known phrasing names the other party. Otherwise the model decides.
  final String? merchant;
}

/// Bank names as they appear in message text. The same list as `tools/sms_corpus`.
const _bankWords = <String, String>{
  'HDFC': r'hdfc',
  'SBI': r'\bsbi\b|state bank',
  'ICICI': r'icici',
  'AXIS': r'axis',
  'YES': r'yes\s*bank',
  'RBL': r'\brbl\b',
  'INDIAN': r'indian bank',
  'PNB': r'\bpnb\b|punjab national',
  'BOB': r'bank of baroda|\bbob\b',
  'CANARA': r'canara',
  'UNION': r'union bank',
  'KOTAK': r'kotak',
  'INDUSIND': r'indusind',
  'IDFC': r'idfc',
  'FEDERAL': r'federal bank',
  'BOI': r'bank of india',
  'CENTRAL': r'central bank',
  'UCO': r'\buco\b',
  'IDBI': r'idbi',
  'AU': r'au small|au bank',
  'BANDHAN': r'bandhan',
};

final _debitWord = RegExp(
  r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted|payment of)\b',
);
final _debitOnly = RegExp(
  r'\b(debited|sent|spent|paid|withdrawn|purchase|purchased|deducted)\b',
);
final _creditWord = RegExp(r'\b(credited|received|deposited|refund(?:ed)?)\b');

final _amountRs = RegExp(
  r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d+)?)',
  caseSensitive: false,
);
final _amountBy = RegExp(r'\b(?:by|of)\s+([\d,]+\.\d+)', caseSensitive: false);
final _last4 = RegExp(
  r'(?:a/c|acct|card|ending)(?:\s+no\.?)?\s*[*x]*(\d{4,})',
  caseSensitive: false,
);

/// "1,00,000.50" -> 10000050. Works on the text so there is no floating point rounding.
int? parsePaise(String text) {
  final plain = text.replaceAll(',', '');
  final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(plain);
  if (m == null) return null;
  final rupees = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(2, '0');
  final paise = int.parse(frac.substring(0, 2));
  // A third decimal digit of 5 or more rounds up, as banks do not print more than two.
  final roundUp = frac.length > 2 && int.parse(frac[2]) >= 5 ? 1 : 0;
  return rupees * 100 + paise + roundUp;
}

/// True when a name is a bank, not a shop. Small models sometimes answer with the bank that sent
/// the SMS, which is never the merchant.
bool looksLikeBankName(String? name) {
  if (name == null) return false;
  final low = name.toLowerCase();
  return low.contains('bank') ||
      _bankWords.values.any((p) => RegExp(p).hasMatch(low));
}

class RuleExtractor {
  const RuleExtractor();

  RuleFields extract(String sms) {
    final low = sms.toLowerCase();
    final match = _amountRs.firstMatch(sms) ?? _amountBy.firstMatch(sms);
    final amount = match == null ? null : parsePaise(match.group(1)!);

    return RuleFields(
      amountPaise: amount,
      direction: _direction(low),
      bank: _bank(low),
      accountKind: _kind(low),
      last4: _lastFour(sms),
      channel: _channel(low),
      reference: _reference(low),
      date: _date(sms),
      merchant: _merchant(sms),
    );
  }

  Direction? _direction(String low) {
    final debit = _debitWord.hasMatch(low);
    final credit = _creditWord.hasMatch(low);
    if (debit && !credit) return Direction.debit;
    if (credit && !debit) return Direction.credit;
    if (debit && credit) {
      // Both words: the first one describes this account ("debited ... credited to X").
      final d = _debitOnly.firstMatch(low);
      final c = _creditWord.firstMatch(low)!;
      return (d != null && d.start < c.start)
          ? Direction.debit
          : Direction.credit;
    }
    return null;
  }

  String? _bank(String low) {
    // UPI handles like anita@okhdfcbank name the other party's bank, so ignore them.
    final text = low.replaceAll(RegExp(r'\S*@\S*'), ' ');
    int? best;
    String? bestBank;
    _bankWords.forEach((name, pattern) {
      final m = RegExp(pattern).firstMatch(text);
      if (m != null && (best == null || m.start < best!)) {
        best = m.start;
        bestBank = name;
      }
    });
    return bestBank;
  }

  AccountKind _kind(String low) {
    if (low.contains('credit card')) return AccountKind.creditCard;
    if (low.contains('card')) return AccountKind.debitCard;
    return AccountKind.savings;
  }

  String? _lastFour(String sms) {
    final digits = _last4.firstMatch(sms)?.group(1);
    if (digits == null || digits.length < 4) return null;
    return digits.substring(digits.length - 4);
  }

  String? _channel(String low) {
    if (RegExp(r'\bupi\b|\bvpa\b|\w@\w').hasMatch(low)) return 'UPI';
    if (low.contains('neft')) return 'NEFT';
    if (low.contains('imps')) return 'IMPS';
    if (RegExp(r'\batm\b').hasMatch(low) || low.contains('withdrawn')) {
      return 'ATM';
    }
    return null;
  }

  String? _reference(String low) {
    final ref = RegExp(
      r'\bref(?:erence)?\.?(?:\s*(?:no|number|id)\.?)?[\s:#-]*(?:upi[\s:-]*)?(\d{6,})',
    ).firstMatch(low);
    if (ref != null) return ref.group(1);
    return RegExp(r'(?<!\d)\d{12}(?!\d)').firstMatch(low)?.group(0);
  }

  static const _months = {
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

  DateTime? _make(int y, int m, int d) {
    if (d < 1 || d > 31 || m < 1 || m > 12) return null;
    if (y < 100) y += 2000;
    final date = DateTime(y, m, d);
    // DateTime rolls 31 Feb over to March; reject that.
    return date.month == m ? date : null;
  }

  /// Indian SMS dates, day first: 05/11/26, 21-10-26, 2026-10-18, 12Oct26, 02-Nov-26.
  DateTime? _date(String sms) {
    var m = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(sms);
    if (m != null) {
      return _make(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }
    m = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})\b').firstMatch(sms);
    if (m != null) {
      return _make(
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
        return _make(int.parse(m.group(3)!), mon, int.parse(m.group(1)!));
      }
    }
    return null;
  }

  static final _merchantPatterns = <RegExp>[
    RegExp(r'UPI-([^-]+)-\S+@', caseSensitive: false),
    RegExp(r'UPI/P2[MP]/\d+/(.+?)\s+(?:not|if)\b', caseSensitive: false),
    RegExp(r'NEFT/([^/)]+)/', caseSensitive: false),
    RegExp(r'NEFT from (.+?)\.', caseSensitive: false),
    RegExp(r'trf to (.+?)\s+ref', caseSensitive: false),
    RegExp(r'\bto (?!VPA|A/c|Acct)(.+?)\s+on\s+\d', caseSensitive: false),
    RegExp(r'\bat (.+?)(?:\s+on\s+\d|\.)', caseSensitive: false),
  ];
  static final _notMerchant = RegExp(
    r'\b(atm|a/c|acct|card|bank|your)\b',
    caseSensitive: false,
  );

  String? _merchant(String sms) {
    // A UPI handle such as swiggy@icici names the payee directly.
    final handle = RegExp(r'([\w.\-]+)@(\w+)').firstMatch(sms);
    for (final p in _merchantPatterns) {
      final v = p.firstMatch(sms)?.group(1)?.trim();
      if (v != null && v.isNotEmpty && !_notMerchant.hasMatch(v)) {
        return v
            .replaceFirst(
              RegExp(r'^(vpa|upi)[\s:-]+', caseSensitive: false),
              '',
            )
            .trim();
      }
    }
    return handle?.group(1);
  }
}
