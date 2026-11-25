/// What a received message is. Only [transaction] goes on to the AI step.
enum SmsKind {
  /// Money moved: a debit, credit, card spend, ATM withdrawal, refund, bill payment received.
  transaction,

  /// One-time password or verification code. Never stored.
  otp,

  /// Advertising or an offer. Never stored.
  promo,

  /// Statement, bill due date, or a future debit ("will be debited"). Kept for card reminders.
  reminder,

  /// A failed or declined payment. No money moved.
  declined,

  /// Balance enquiries and anything else.
  other,
}

class SmsClassification {
  const SmsClassification(this.kind, this.reason);
  final SmsKind kind;

  /// Short code for why, for the pipeline log. Never contains message text.
  final String reason;

  @override
  String toString() => '${kind.name}:$reason';
}

/// Rules that sort bank SMS. They lean towards keeping a message: wrongly keeping a promo costs
/// a little work later, wrongly dropping a transaction loses data.
class SmsClassifier {
  const SmsClassifier();

  static final _amount = RegExp(
    r'(rs\.?|inr|₹|usd|eur|gbp|aed|sgd)\s*[\d,]+(\.\d+)?',
    caseSensitive: false,
  );

  /// Words that say money has actually moved.
  static final _strong = RegExp(
    r'\b(debited|credited|spent|withdrawn|deducted|debit alert|credit alert|card.{0,40}used (for|at))\b',
    caseSensitive: false,
  );

  /// Words that suggest a payment but also appear in other messages.
  static final _weak = RegExp(
    r'\b(paid|received|sent|transferred|purchase|payment|txn|transaction|withdrawal|refund|fastag|toll)\b',
    caseSensitive: false,
  );

  static final _otp = RegExp(
    r'\b(otp|one[- ]time password|verification code|security code|do not share|never share)\b',
    caseSensitive: false,
  );

  static final _declined = RegExp(
    r'\b(declined|failed|unsuccessful|not debited|could not be processed|rejected)\b',
    caseSensitive: false,
  );

  /// A failed payment that was refunded is still money coming back.
  static final _reversed = RegExp(
    r'\b(credited back|reversed|reversal|refunded)\b',
    caseSensitive: false,
  );

  static final _future = RegExp(
    r'\b(will be (debited|deducted|charged|auto[- ]?debited)|scheduled|upcoming|standing instruction|auto[- ]?debit (on|due)|mandate)\b',
    caseSensitive: false,
  );

  static final _statement = RegExp(
    r'\b(statement|amount due|total due|minimum (amount )?due|due date|pay by|payment due|bill (of|for|is))\b',
    caseSensitive: false,
  );

  static final _promo = RegExp(
    r'\b(offer|discount|apply now|pre-?approved|limited (time|period)|t&c|tnc|terms apply|click|exclusive|win|congratulations|upgrade|loan|emi offer|zero fee|lifetime free|download the app|visit|shop now)\b|https?://',
    caseSensitive: false,
  );

  SmsClassification classify(String body, {String sender = ''}) {
    final hasAmount = _amount.hasMatch(body);
    final strong = _strong.hasMatch(body);
    final weak = _weak.hasMatch(body);

    // A code message is an OTP unless it also reports money that has really moved.
    if (_otp.hasMatch(body) && !strong) {
      return const SmsClassification(SmsKind.otp, 'otp_words');
    }
    if (!hasAmount) {
      if (_promo.hasMatch(body)) {
        return const SmsClassification(SmsKind.promo, 'promo_no_amount');
      }
      return const SmsClassification(SmsKind.other, 'no_amount');
    }
    // Failed payments: no money moved, unless it was taken and then given back.
    if (_declined.hasMatch(body) && !_reversed.hasMatch(body)) {
      return const SmsClassification(SmsKind.declined, 'declined_words');
    }
    // A future debit is a reminder, not a transaction.
    if (_future.hasMatch(body) &&
        !RegExp(
          r'\b(has been|was|is) (debited|deducted)\b',
          caseSensitive: false,
        ).hasMatch(body)) {
      return const SmsClassification(SmsKind.reminder, 'future_debit');
    }
    if (strong) {
      return const SmsClassification(SmsKind.transaction, 'strong_movement');
    }
    if (_statement.hasMatch(body)) {
      return const SmsClassification(SmsKind.reminder, 'statement_or_due');
    }
    if (_promo.hasMatch(body)) {
      return const SmsClassification(SmsKind.promo, 'promo_words');
    }
    if (weak) {
      return const SmsClassification(SmsKind.transaction, 'weak_movement');
    }
    return const SmsClassification(SmsKind.other, 'amount_only');
  }
}
