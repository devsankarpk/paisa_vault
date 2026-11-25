/// What the user asked to find. Every field that is set must match (filters combine).
class TransactionFilter {
  const TransactionFilter({
    this.from,
    this.to,
    this.category,
    this.amountPaise,
    this.text = '',
  });

  /// First and last day, both included. Only the date part is used.
  final DateTime? from;
  final DateTime? to;
  final String? category;

  /// Exact amount in paise.
  final int? amountPaise;

  /// Matches part of the merchant name or the note, ignoring case.
  final String text;

  bool get isEmpty =>
      from == null &&
      to == null &&
      category == null &&
      amountPaise == null &&
      text.trim().isEmpty;

  TransactionFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? category,
    int? amountPaise,
    String? text,
    bool clearDates = false,
    bool clearCategory = false,
    bool clearAmount = false,
  }) => TransactionFilter(
    from: clearDates ? null : from ?? this.from,
    to: clearDates ? null : to ?? this.to,
    category: clearCategory ? null : category ?? this.category,
    amountPaise: clearAmount ? null : amountPaise ?? this.amountPaise,
    text: text ?? this.text,
  );
}
