import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/app_logger.dart';
import 'package:paisa_vault/core/providers.dart';
import 'package:paisa_vault/services/llm_engine.dart';
import 'package:paisa_vault/services/sms_source.dart';
import 'package:paisa_vault/testing/fakes.dart';

void main() {
  test('redact hides long digit runs', () {
    expect(redact('card 4111111111111111 used'), 'card <redacted> used');
    expect(redact('last4 1234'), 'last4 1234');
  });

  test('fakes work through provider overrides', () async {
    final sms = FakeSmsSource();
    final llm = FakeLlmEngine(const LlmExtraction(merchant: 'SWIGGY'));
    final container = ProviderContainer(
      overrides: [
        smsSourceProvider.overrideWithValue(sms),
        llmEngineProvider.overrideWithValue(llm),
        clockProvider.overrideWithValue(FakeClock(DateTime(2026, 11, 20))),
      ],
    );
    addTearDown(container.dispose);

    final got = container.read(smsSourceProvider).messages.first;
    sms.emit(
      IncomingSms(sender: 'VM-HDFCBK', body: 'x', receivedAt: DateTime(2026)),
    );
    expect((await got).sender, 'VM-HDFCBK');

    final out = await container
        .read(llmEngineProvider)
        .extract('x', categories: const ['Food']);
    expect(out.merchant, 'SWIGGY');
    expect(container.read(clockProvider).now().year, 2026);
  });
}
