import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/card_reader.dart';
import '../services/llm_engine.dart';
import '../services/sms_source.dart';
import '../services/text_scanner.dart';
import 'clock.dart';

// Real implementations are chosen in main.dart; tests override with fakes.
final clockProvider = Provider<Clock>((_) => const SystemClock());
final smsSourceProvider = Provider<SmsSource>(
  (_) => throw UnimplementedError(),
);
final llmEngineProvider = Provider<LlmEngine>(
  (_) => throw UnimplementedError(),
);
final cardReaderProvider = Provider<CardReader>(
  (_) => throw UnimplementedError(),
);
final textScannerProvider = Provider<TextScanner>(
  (_) => throw UnimplementedError(),
);
