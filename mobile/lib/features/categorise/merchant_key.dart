/// Makes a merchant name comparable: upper case, letters only, single spaces.
/// "Swiggy Instamart 4521" and "SWIGGY-INSTAMART" both give "SWIGGY INSTAMART".
String merchantKey(String? name) {
  if (name == null) return '';
  return name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// True when two merchant keys are the same shop: equal, or one is the other plus extra words
/// ("SWIGGY INSTAMART" matches "SWIGGY"). Names with fewer than 4 letters in the first word
/// match only when equal, so "ABC" does not swallow "ABCD STORES".
bool sameMerchant(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final shorter = a.length <= b.length ? a : b;
  final longer = a.length <= b.length ? b : a;
  if (shorter.length < 4) return false;
  return longer.startsWith('$shorter ');
}
