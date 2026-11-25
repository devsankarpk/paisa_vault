import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/app_logger.dart';
import 'package:paisa_vault/core/crash_log.dart';
import 'package:paisa_vault/features/model/model_diagnostics.dart';

// Distinctive text that must never reach a log.
const canaryShop = 'CANARYMART';
const canaryRef = '987654321012';
const secretSms =
    'Rs 7,777.77 spent on HDFC Bank Card x4321 at $canaryShop. UPI Ref $canaryRef';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('pv_log'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('redact hides long digit runs such as card or reference numbers', () {
    expect(redact('ref 987654321012 ok'), 'ref <redacted> ok');
    expect(redact('last4 4321 ok'), 'last4 4321 ok');
  });

  test(
    'a crash line has the error type and stack, never the error message',
    () {
      final line = CrashLog.describe(
        FormatException('bad input: $secretSms'),
        StackTrace.fromString(
          '#0 parse (package:paisa_vault/a.dart:12:3)\n#1 run (package:paisa_vault/b.dart:40:9)',
        ),
        DateTime.utc(2026, 11, 25),
      );
      expect(line, contains('FormatException'));
      expect(line, contains('a.dart:12:3'));
      expect(line, isNot(contains(canaryShop)));
      expect(line, isNot(contains(canaryRef)));
      expect(line, isNot(contains('7,777')));
    },
  );

  test('the crash file is written and holds no message text', () async {
    final log = CrashLog(() async => dir);
    await log.record(
      StateError('could not read $secretSms'),
      StackTrace.fromString('#0 f (package:paisa_vault/x.dart:1:1)'),
    );
    final text = File('${dir.path}/crash.log').readAsStringSync();
    expect(text, contains('StateError'));
    expect(text, isNot(contains(canaryShop)));
    expect(text, isNot(contains('4321')));
  });

  test('the crash file does not grow without limit', () async {
    final log = CrashLog(() async => dir);
    for (var i = 0; i < 700; i++) {
      await log.record(
        StateError('x'),
        StackTrace.fromString('#0 f (a.dart:1:1)\n' * 6),
      );
    }
    expect(
      File('${dir.path}/crash.log').lengthSync(),
      lessThan(CrashLog.maxBytes + 2000),
    );
  });

  test(
    'model diagnostics redact long numbers even if a caller slips',
    () async {
      await ModelDiagnostics(() async => dir).note('failed ref=$canaryRef');
      final text = File('${dir.path}/model_runs.log').readAsStringSync();
      expect(text, isNot(contains(canaryRef)));
      expect(text, contains('<redacted>'));
    },
  );
}
