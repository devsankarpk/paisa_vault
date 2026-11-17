class CardRead {
  const CardRead({required this.number, this.expiryMonth, this.expiryYear});

  final String number;
  final int? expiryMonth;
  final int? expiryYear;
}

/// NFC card reading (Android only). Returns null when the card cannot be read.
abstract class CardReader {
  Future<bool> get isAvailable;
  Future<CardRead?> read();
}
