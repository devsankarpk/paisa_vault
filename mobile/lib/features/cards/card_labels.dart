import '../../core/db/app_database.dart';

String cardTypeLabel(CardType t) =>
    t == CardType.credit ? 'Credit card' : 'Debit card';

String networkLabel(CardNetwork n) => switch (n) {
  CardNetwork.visa => 'Visa',
  CardNetwork.mastercard => 'Mastercard',
  CardNetwork.rupay => 'RuPay',
  CardNetwork.amex => 'American Express',
  CardNetwork.diners => 'Diners Club',
  CardNetwork.other => 'Other',
};

String expiryLabel(PvCard c) => c.expiryMonth == null
    ? 'Not entered'
    : '${c.expiryMonth.toString().padLeft(2, '0')}/${(c.expiryYear! % 100).toString().padLeft(2, '0')}';

/// "4821" -> "•••• 4821".
String maskedLast4(String last4) => '•••• $last4';

String dayLabel(int d) => 'the $d${_suffix(d)} of each month';

String _suffix(int d) {
  if (d >= 11 && d <= 13) return 'th';
  return switch (d % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
