/// A bank SMS received by the phone. Never log [body].
class IncomingSms {
  const IncomingSms({
    required this.sender,
    required this.body,
    required this.receivedAt,
    this.simSubscriptionId,
  });

  final String sender;
  final String body;
  final DateTime receivedAt;
  final int? simSubscriptionId;
}

/// Where new SMS come from: the Android receiver or the iPhone Shortcut inbox.
abstract class SmsSource {
  /// New messages as they arrive (Android) or are found on app open (iPhone).
  Stream<IncomingSms> get messages;
}
