import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/app_logger.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  test('redact hides long digit runs', () {
    expect(redact('card 4111111111111111 used'), 'card <redacted> used');
    expect(redact('last4 1234'), 'last4 1234');
  });

  test('fakes work through provider overrides', () async {
    final sms = FakeSmsSource();
    final llm = FakeLlmEngine(['{"merchant": "SWIGGY"}']);
    final container = ProviderContainer(
      overrides: [
        smsSourceProvider.overrideWithValue(sms),
        llmEngineProvider.overrideWithValue(llm),
        clockProvider.overrideWithValue(FakeClock(DateTime(2026, 11, 20))),
      ],
    );
    addTearDown(container.dispose);

    final got = container.read(smsSourceProvider).arrivals.first;
    sms.emit(
      IncomingSms(sender: 'VM-HDFCBK', body: 'x', receivedAt: DateTime(2026)),
    );
    await got;
    expect((await sms.pending()).single.sms.sender, 'VM-HDFCBK');

    final out = await container.read(llmEngineProvider).generate('x');
    expect(out, contains('SWIGGY'));
    expect(container.read(clockProvider).now().year, 2026);
  });
}
