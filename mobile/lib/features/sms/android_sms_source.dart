import 'dart:async';

import 'package:flutter/services.dart';

import '../../services/sms_source.dart';

/// Talks to the Kotlin receiver and encrypted stage (see SmsStage.kt, MainActivity.kt).
class AndroidSmsSource implements SmsSource {
  AndroidSmsSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'arrived') _arrivals.add(null);
    });
  }

  static const _channel = MethodChannel('paisa_vault/sms');
  final _arrivals = StreamController<void>.broadcast();

  @override
  Stream<void> get arrivals => _arrivals.stream;

  @override
  Future<bool> get hasPermission async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<List<StagedSms>> pending() async {
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('pending') ??
        const [];
    return [
      for (final r in rows)
        StagedSms(
          r['id']! as String,
          IncomingSms(
            sender: r['sender']! as String,
            body: r['body']! as String,
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              r['receivedAt']! as int,
            ),
            simSubscriptionId: (r['sub']! as int) < 0 ? null : r['sub']! as int,
          ),
        ),
    ];
  }

  @override
  Future<void> acknowledge(List<String> ids) =>
      _channel.invokeMethod<void>('acknowledge', {'ids': ids});
}

/// iPhone: the Shortcut inbox is added in its own task. Until then nothing arrives.
class NoSmsSource implements SmsSource {
  @override
  Stream<void> get arrivals => const Stream.empty();
  @override
  Future<bool> get hasPermission async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<List<StagedSms>> pending() async => const [];
  @override
  Future<void> acknowledge(List<String> ids) async {}
}
