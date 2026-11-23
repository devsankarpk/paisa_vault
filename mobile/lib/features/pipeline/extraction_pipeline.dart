import '../../core/db/tables.dart';
import '../../services/llm_engine.dart';
import 'amount_check.dart';
import 'model_reply.dart';
import 'prompt.dart';
import 'rule_extractor.dart';

/// A transaction read from one SMS, ready to be mapped to an account and stored.
class ExtractedTransaction {
  const ExtractedTransaction({
    required this.amountPaise,
    required this.direction,
    required this.bank,
    required this.accountKind,
    required this.last4,
    required this.channel,
    required this.merchant,
    required this.category,
    required this.reference,
    required this.date,
    required this.status,
    required this.confirmReason,
    required this.modelId,
    required this.promptVersion,
  });

  final int amountPaise;
  final Direction direction;
  final String? bank;
  final AccountKind accountKind;
  final String? last4;
  final String? channel;
  final String? merchant;
  final String? category;
  final String? reference;
  final DateTime? date;

  /// [TransactionStatus.pleaseConfirm] when something could not be checked.
  final TransactionStatus status;

  /// Short code for why confirmation is needed. Never contains message text.
  final String? confirmReason;
  final String? modelId;
  final String? promptVersion;
}

/// Why the SMS did not produce a transaction at all.
enum NoTransaction { noAmount, noDirection, amountNotInText }

class ExtractionResult {
  const ExtractionResult.transaction(ExtractedTransaction t)
    : transaction = t,
      reason = null;
  const ExtractionResult.none(NoTransaction r) : transaction = null, reason = r;

  final ExtractedTransaction? transaction;
  final NoTransaction? reason;
}

/// Rules first, then the model for merchant, category and channel, then safety checks.
class ExtractionPipeline {
  ExtractionPipeline(
    this._llm, {
    required this.categories,
    this.rules = const RuleExtractor(),
  });

  /// Null while no model is available (before the model is installed). Rules still run, and the
  /// transaction is marked please confirm unless the rules found the merchant.
  final LlmEngine? _llm;
  final List<String> categories;
  final RuleExtractor rules;

  /// Tries the model twice. A bad reply twice leaves merchant and category empty.
  static const attempts = 2;

  Future<ExtractionResult> process(String sms) async {
    final fields = rules.extract(sms);
    final amount = fields.amountPaise;
    if (amount == null) {
      return const ExtractionResult.none(NoTransaction.noAmount);
    }
    if (fields.direction == null) {
      return const ExtractionResult.none(NoTransaction.noDirection);
    }
    if (!amountAppearsInSms(amount, sms)) {
      return const ExtractionResult.none(NoTransaction.amountNotInText);
    }

    ModelReply? reply;
    String? modelError;
    final llm = _llm;
    for (var i = 0; llm != null && i < attempts && reply == null; i++) {
      try {
        reply = parseModelReply(
          await llm.generate(buildPrompt(sms, categories)),
          categories: categories,
        );
        if (reply == null) modelError = 'bad_reply';
      } catch (_) {
        modelError = 'model_error';
      }
    }

    // A rule-found merchant is trusted over the model's guess.
    final modelMerchant = looksLikeBankName(reply?.merchant)
        ? null
        : reply?.merchant;
    final merchant = fields.merchant ?? modelMerchant;
    final channel = fields.channel ?? reply?.channel;
    // Without a model the rules alone must have found the merchant; with one, a bad reply twice
    // means confirm.
    final confirm = llm == null ? merchant == null : reply == null;
    if (llm == null && confirm) modelError = 'no_model';

    return ExtractionResult.transaction(
      ExtractedTransaction(
        amountPaise: amount,
        direction: fields.direction!,
        bank: fields.bank,
        accountKind: fields.accountKind,
        last4: fields.last4,
        channel: channel,
        merchant: merchant,
        category: reply?.category,
        reference: fields.reference,
        date: fields.date,
        status: confirm
            ? TransactionStatus.pleaseConfirm
            : TransactionStatus.confirmed,
        confirmReason: confirm ? modelError : null,
        modelId: llm?.modelId,
        promptVersion: llm == null ? null : promptVersion,
      ),
    );
  }
}
