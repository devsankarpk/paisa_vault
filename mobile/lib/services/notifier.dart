/// Shows a notification on the phone. Everything is local; nothing is sent anywhere.
abstract class AlertNotifier {
  /// Asks for notification permission if not asked yet. Returns whether it is allowed.
  Future<bool> requestPermission();

  /// [id] replaces an earlier notification with the same id.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Does nothing. Used where no real notifier is set up (tests, unsupported platforms).
class SilentAlertNotifier implements AlertNotifier {
  const SilentAlertNotifier();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}
