import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// When this build stops working because its signing runs out. Null when it does not apply
/// (Android, a store build) or cannot be read.
abstract class SigningExpiry {
  Future<DateTime?> expiry();
}

class NativeSigningExpiry implements SigningExpiry {
  static const _channel = MethodChannel('paisa_vault/sms');

  @override
  Future<DateTime?> expiry() async {
    try {
      final ms = await _channel.invokeMethod<int>('signingExpiry');
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

final signingExpiryProvider = Provider<SigningExpiry>(
  (_) => NativeSigningExpiry(),
);

/// Whole days left, or null when the build does not expire (or it is unknown).
final signingDaysLeftProvider = FutureProvider<int?>((ref) async {
  final at = await ref.watch(signingExpiryProvider).expiry();
  if (at == null) return null;
  return daysUntil(at, ref.watch(clockProvider).now());
});

int daysUntil(DateTime expiry, DateTime now) =>
    (expiry.difference(now).inHours / 24).floor();

/// Show the banner from this many days before the expiry.
const signingWarnDays = 3;
