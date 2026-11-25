import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/db/key_store.dart';
import 'package:paisa_vault/core/secret_store.dart';
import 'package:paisa_vault/features/settings/erase_service.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  test('erase everything removes the database, keys, PIN, logs and staged messages', () async {
    final dir = Directory.systemTemp.createTempSync('pv_erase');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final n in [
      'main.db',
      'main.db-wal',
      'model_runs.log',
      'intent_runs.log',
    ]) {
      File('${dir.path}/$n').writeAsStringSync('x');
    }
    // not personal data: must stay
    Directory('${dir.path}/models').createSync();
    File('${dir.path}/models/qwen.gguf').writeAsStringSync('GGUF');

    final keys = MemoryKeyStore();
    final before = await keys.keyFor('main');
    final secrets = MemorySecretStore();
    for (final k in EraseService.secretKeys) {
      await secrets.write(k, 'v');
    }
    await secrets.write('unrelated', 'keep');
    final sms = FakeSmsSource()
      ..emit(IncomingSms(sender: '', body: 'x', receivedAt: DateTime(2026)));
    var closed = false;

    await EraseService(
      appSupport: dir,
      keyStore: keys,
      secrets: secrets,
      sms: sms,
      closeDatabase: () async => closed = true,
    ).eraseAll();

    expect(closed, isTrue);
    for (final n in [
      'main.db',
      'main.db-wal',
      'model_runs.log',
      'intent_runs.log',
    ]) {
      expect(File('${dir.path}/$n').existsSync(), isFalse, reason: n);
    }
    expect(File('${dir.path}/models/qwen.gguf').existsSync(), isTrue);
    expect(await keys.keyFor('main'), isNot(before)); // the old key is gone
    for (final k in EraseService.secretKeys) {
      expect(await secrets.read(k), isNull, reason: k);
    }
    expect(await secrets.read('unrelated'), 'keep');
    expect(sms.acknowledged, hasLength(1));
  });
}
