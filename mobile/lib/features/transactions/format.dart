import '../../core/db/tables.dart';

/// 12345678 paise -> "1,23,456.78" (Indian digit grouping).
String formatRupees(int paise) {
  final rupees = paise ~/ 100;
  final fraction = (paise % 100).toString().padLeft(2, '0');
  final digits = rupees.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final parts = <String>[];
    var rest = head;
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$tail';
  }
  return '$grouped.$fraction';
}

String signedAmount(int paise, Direction d) =>
    '${d == Direction.debit ? '-' : '+'}₹${formatRupees(paise)}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String accountKindLabel(String? kind) => switch (kind) {
  'creditCard' => 'Credit card',
  'debitCard' => 'Debit card',
  'savings' => 'Account',
  'current' => 'Current account',
  'wallet' => 'Wallet',
  'upi' => 'UPI',
  _ => 'Unknown',
};

String confirmReasonLabel(String? reason) => switch (reason) {
  'no_model' => 'No merchant found yet (the on-device model is not installed)',
  'bad_reply' => 'The model gave an unusable answer',
  'model_error' => 'The model failed to run',
  _ => 'Needs checking',
};
