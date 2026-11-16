// Pulls a card number and expiry out of OCR text lines.
// Only last 4 digits and flags leave this file's results.

class ScanFindings {
  ScanFindings({
    this.numberFound = false,
    this.length = 0,
    this.last4 = '',
    this.luhn = false,
    this.expiryFound = false,
    this.expiry = '',
    this.candidates = 0,
  });
  final bool numberFound;
  final int length;
  final String last4;
  final bool luhn;
  final bool expiryFound;
  final String expiry; // MM/YY
  final int candidates;
}

bool luhnOk(String d) {
  var sum = 0;
  var alt = false;
  for (var i = d.length - 1; i >= 0; i--) {
    var n = int.parse(d[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return d.isNotEmpty && sum % 10 == 0;
}

/// Digits that look like a card number: 13 to 19 digits, spaces or dashes allowed
/// between groups. Prefers a Luhn-valid candidate.
ScanFindings parseCardText(List<String> lines) {
  final base = _parse(lines);
  if (base.numberFound && base.luhn && base.expiryFound) return base;
  // Flat print is often read as look-alike letters. Repair those lines, but accept
  // a repaired number only when the card checksum passes.
  final fixed = _fixLookalikes(lines);
  final alt = _parse(fixed);
  final useAltNumber =
      !(base.numberFound && base.luhn) && alt.numberFound && alt.luhn;
  final src = useAltNumber ? alt : base;
  final expSrc = base.expiryFound ? base : alt;
  return ScanFindings(
    numberFound: src.numberFound,
    length: src.length,
    last4: src.last4,
    luhn: src.luhn,
    expiryFound: expSrc.expiryFound,
    expiry: expSrc.expiry,
    candidates: src.candidates,
  );
}

const _lookalike = {
  'O': '0',
  'Q': '0',
  'D': '0',
  'I': '1',
  'L': '1',
  'Z': '2',
  'A': '4',
  'S': '5',
  'G': '6',
  'T': '7',
  'B': '8',
};

List<String> _fixLookalikes(List<String> lines) {
  return [
    for (final l in lines)
      () {
        final t = l.trim();
        if (!RegExp(r'^[0-9A-Za-z \-/]+$').hasMatch(t)) {
          return l;
        }
        final b = StringBuffer();
        for (final ch in t.split('')) {
          if (RegExp(r'[0-9 \-/]').hasMatch(ch)) {
            b.write(ch);
          } else {
            final m = _lookalike[ch.toUpperCase()];
            if (m == null) {
              return l; // a real letter: leave the whole line alone
            }
            b.write(m);
          }
        }
        return b.toString();
      }(),
  ];
}

ScanFindings _parse(List<String> lines) {
  final text = lines.join('\n');
  // Fix common OCR mix-ups only inside digit-like groups.
  final cands = <String>[];
  final re = RegExp(r'(?<!\d)(\d[\d \-.,·|]{11,26}\d)(?!\d)');
  for (final m in re.allMatches(text)) {
    final d = m.group(1)!.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length >= 13 && d.length <= 19) cands.add(d);
  }
  // Number printed over several lines (8+8, or four blocks of 4): join runs of
  // neighbouring lines that hold only digits, spaces or dashes.
  final digitLines = <String>[];
  for (final l in lines) {
    final t = l.trim();
    final d = t.replaceAll(RegExp(r'[^\d]'), '');
    final onlyDigits = RegExp(r'^[\d \-.,·|]+$').hasMatch(t);
    if (onlyDigits && d.length >= 2) {
      digitLines.add(d);
    } else {
      digitLines.add(''); // a text line breaks the run
    }
  }
  for (var i = 0; i < digitLines.length; i++) {
    if (digitLines[i].isEmpty) continue;
    var joined = '';
    for (var j = i; j < digitLines.length && j < i + 6; j++) {
      if (digitLines[j].isEmpty) break;
      joined += digitLines[j];
      if (j > i && joined.length >= 13 && joined.length <= 19) {
        cands.add(joined);
      }
      if (joined.length > 19) break;
    }
  }
  String? pick;
  for (final c in cands) {
    if (luhnOk(c)) {
      pick = c;
      break;
    }
  }
  if (pick == null && cands.isNotEmpty) {
    // No checksum match: prefer a 16-digit candidate, then the first one.
    pick = cands.firstWhere((c) => c.length == 16, orElse: () => cands.first);
  }

  // Expiry: MM/YY or MM-YY, month 01..12, not preceded by more digits.
  String expiry = '';
  final em = RegExp(r'(?<!\d)(0[1-9]|1[0-2])\s?[/\-]\s?(\d{2})(?!\d)')
      .allMatches(text)
      .toList();
  if (em.isNotEmpty) {
    // prefer the last match: "valid thru" is usually after "member since"
    final m = em.last;
    expiry = '${m.group(1)}/${m.group(2)}';
  }
  return ScanFindings(
    numberFound: pick != null,
    length: pick?.length ?? 0,
    last4: pick == null ? '' : pick.substring(pick.length - 4),
    luhn: pick != null && luhnOk(pick),
    expiryFound: expiry.isNotEmpty,
    expiry: expiry,
    candidates: cands.toSet().length,
  );
}
