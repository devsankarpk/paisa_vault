/// Safety check from the spec: an amount must literally appear in the SMS text. Guards against
/// a misread or invented amount. [paise] is the amount in paise.
bool amountAppearsInSms(int paise, String sms) {
  final rupees = paise ~/ 100;
  final fraction = (paise % 100).toString().padLeft(2, '0');
  final plain = sms.replaceAll(',', '');
  final candidates = <String>{
    '$rupees.$fraction',
    if (fraction == '00') '$rupees',
    // 12.50 is also commonly written 12.5
    if (fraction.endsWith('0') && fraction != '00') '$rupees.${fraction[0]}',
  };
  return candidates.any(
    (c) =>
        RegExp('(?<!\\d)(?<!\\d\\.)${RegExp.escape(c)}(?!\\d|\\.\\d)')
            .hasMatch(plain),
  );
}
