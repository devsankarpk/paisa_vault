/// Bump when the prompt or the expected reply changes. Stored on each transaction so results
/// can be re-checked after a model or prompt update.
const promptVersion = 'p1';

const _template = r'''Name the merchant and category of this Indian bank SMS.
Reply with one JSON object only: {"merchant": ..., "category": ..., "channel": ...}
- merchant is the shop, app or person paid (or the payer for money received). Never the bank that sent the SMS. Use null for ATM cash or when none is named.
- channel is one of UPI, NEFT, IMPS, ATM, POS (card at a shop), online (card on a website or app).
- category must be one of: __CATS__.

SMS: Rs.250.00 spent on HDFC Bank Card x1234 at ZOMATO on 12-10-26.
{"merchant": "ZOMATO", "category": "Food", "channel": "POS"}
SMS: Rs 5,000.00 credited to A/c XX9876 on 01-11-26 by NEFT from ACME PVT LTD. Ref 998877.
{"merchant": "ACME PVT LTD", "category": "Income", "channel": "NEFT"}
SMS: Rs 2,000 withdrawn at SBI ATM from A/c XX9876 on 14-10-26.
{"merchant": null, "category": "Other", "channel": "ATM"}
SMS: __SMS__
''';

String buildPrompt(String sms, List<String> categories) => _template
    .replaceAll('__CATS__', categories.join(', '))
    .replaceAll('__SMS__', sms);
