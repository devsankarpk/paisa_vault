import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_sync/secure_channel.dart';

void main() {
  test(
    'two phones agree on a key and a code, and can read each other',
    () async {
      final a = await SecureChannel.create();
      final b = await SecureChannel.create();
      final sa = await a.sessionWith(b.publicKey);
      final sb = await b.sessionWith(a.publicKey);
      expect(sa.code, sb.code);
      expect(sa.code.length, 6);
      final msg = await sa.encrypt('hello');
      expect(await sb.decrypt(msg), 'hello');
    },
  );

  test('a third phone cannot read the message', () async {
    final a = await SecureChannel.create();
    final b = await SecureChannel.create();
    final c = await SecureChannel.create();
    final sab = await a.sessionWith(b.publicKey);
    final sc = await c.sessionWith(a.publicKey);
    final msg = await sab.encrypt('secret');
    expect(() => sc.decrypt(msg), throwsA(anything));
  });

  test('a changed message is rejected', () async {
    final a = await SecureChannel.create();
    final b = await SecureChannel.create();
    final sa = await a.sessionWith(b.publicKey);
    final sb = await b.sessionWith(a.publicKey);
    final msg = await sa.encrypt('pay 100');
    msg['ct'] = msg['ct']!.replaceFirst(
      msg['ct']![0],
      msg['ct']![0] == 'A' ? 'B' : 'A',
    );
    expect(() => sb.decrypt(msg), throwsA(anything));
  });
}
