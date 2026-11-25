import 'package:drift/drift.dart';

enum AccountKind { savings, current, creditCard, debitCard, wallet, upi }

enum AccountStatus { confirmed, pending }

enum Direction { debit, credit }

enum TransactionStatus { confirmed, pleaseConfirm }

enum RawMessageStatus { newMessage, processed, ignored, failed }

/// Key-value app settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Banks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Short stable code such as HDFC, SBI.
  TextColumn get code => text().unique()();
  TextColumn get name => text()();

  /// Comma-separated normalised SMS sender headers, e.g. "HDFCBK,HDFCBN".
  TextColumn get senderIds => text().withDefault(const Constant(''))();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bankId => integer().nullable().references(Banks, #id)();
  TextColumn get kind => textEnum<AccountKind>()();
  TextColumn get last4 => text().withLength(min: 4, max: 4)();
  TextColumn get label => text().nullable()();

  /// Created from an SMS with an unknown last 4: needs the user to confirm.
  TextColumn get status => textEnum<AccountStatus>().withDefault(
    Constant(AccountStatus.confirmed.name),
  )();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bankId, kind, last4},
  ];
}

@TableIndex(name: 'raw_messages_hash', columns: {#contentHash})
@TableIndex(name: 'raw_messages_received', columns: {#receivedAt})
class RawMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sender => text()();

  /// SMS text. Never logged. Purged after 30 to 90 days.
  TextColumn get body => text()();
  DateTimeColumn get receivedAt => dateTime()();
  IntColumn get simSubscriptionId => integer().nullable()();

  /// Hash of sender and body, to spot the same SMS saved twice (two Shortcut automations).
  TextColumn get contentHash => text()();
  TextColumn get status => textEnum<RawMessageStatus>().withDefault(
    Constant(RawMessageStatus.newMessage.name),
  )();
  DateTimeColumn get createdAt => dateTime()();
}

@TableIndex(name: 'txn_date', columns: {#occurredAt})
@TableIndex(name: 'txn_amount_date', columns: {#amountPaise, #occurredAt})
@TableIndex(name: 'txn_category_date', columns: {#categoryId, #occurredAt})
@TableIndex(name: 'txn_fingerprint', columns: {#fingerprint})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get rawMessageId =>
      integer().nullable().references(RawMessages, #id)();

  /// Amount in paise (1/100 rupee), always positive. [direction] gives the sign.
  IntColumn get amountPaise => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get direction => textEnum<Direction>()();
  TextColumn get channel => text().nullable()();
  TextColumn get merchant => text().nullable()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  /// Filled in Phase 1B when categories exist.
  IntColumn get categoryId => integer().nullable()();
  TextColumn get status => textEnum<TransactionStatus>().withDefault(
    Constant(TransactionStatus.confirmed.name),
  )();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();

  // Added in schema v2: what the extraction read, kept on the transaction until accounts and
  // categories are linked (Phase 1A week 4 and Phase 1B).
  /// Short bank code such as HDFC, or null when the message did not name the bank.
  TextColumn get bankCode => text().nullable()();
  TextColumn get last4 => text().nullable()();
  TextColumn get accountKind => text().nullable()();

  /// Category name until the categories table exists.
  TextColumn get categoryName => text().nullable()();

  /// Why the transaction needs confirming (a short code, never message text).
  TextColumn get confirmReason => text().nullable()();

  /// True once the user edited a field, so a later re-check never overwrites it.
  BoolColumn get userCorrected =>
      boolean().withDefault(const Constant(false))();

  /// Hash of bank, last 4, amount, reference and date for duplicate checks.
  TextColumn get fingerprint => text()();
  DateTimeColumn get occurredAt => dateTime()();
  BoolColumn get shared => boolean().withDefault(const Constant(false))();
  BoolColumn get selfTransfer => boolean().withDefault(const Constant(false))();
  TextColumn get modelId => text().nullable()();
  TextColumn get promptVersion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// A learned or user-made rule: this merchant always gets this category. The key is the
/// merchant name made comparable (see merchantKey), so "Swiggy " and "SWIGGY" are one rule.
class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchantKey => text().unique()();
  TextColumn get categoryName => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Local diagnostics. Messages must never contain SMS text or card numbers.
class PipelineLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get stage => text()();
  TextColumn get level => text()();
  TextColumn get message => text()();
  IntColumn get rawMessageId => integer().nullable()();
}

/// Reserved for Phase 2: keyed hashes of hidden transactions, so a re-sent SMS stays hidden
/// while the vault is locked.
class HiddenHash extends Table {
  TextColumn get hash => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {hash};
}
