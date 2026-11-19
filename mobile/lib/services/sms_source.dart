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

/// A message waiting in the native staging area until the app has stored it.
class StagedSms {
  const StagedSms(this.id, this.sms);
  final String id;
  final IncomingSms sms;
}

/// Where new SMS come from: the Android receiver or the iPhone Shortcut inbox.
///
/// Messages are first held by the native side (works while the app is closed). The app reads
/// them with [pending], saves them, and only then calls [acknowledge], so nothing is lost if the
/// app is killed halfway.
abstract class SmsSource {
  /// Fires when a new message was just staged while the app is running.
  Stream<void> get arrivals;

  Future<bool> get hasPermission;
  Future<bool> requestPermission();

  Future<List<StagedSms>> pending();
  Future<void> acknowledge(List<String> ids);
}
