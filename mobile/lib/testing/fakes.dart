import 'dart:async';
import 'dart:typed_data';

import '../core/clock.dart';
import '../services/card_reader.dart';
import '../services/llm_engine.dart';
import '../services/sms_source.dart';
import '../services/text_scanner.dart';

class FakeClock implements Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class FakeSmsSource implements SmsSource {
  final _controller = StreamController<IncomingSms>.broadcast();
  void emit(IncomingSms sms) => _controller.add(sms);
  @override
  Stream<IncomingSms> get messages => _controller.stream;
}

class FakeLlmEngine implements LlmEngine {
  FakeLlmEngine(this.result);
  LlmExtraction result;
  bool loaded = false;
  @override
  Future<void> load() async => loaded = true;
  @override
  Future<LlmExtraction> extract(
    String smsText, {
    required List<String> categories,
  }) async => result;
  @override
  Future<void> dispose() async => loaded = false;
}

class FakeCardReader implements CardReader {
  FakeCardReader({this.available = true, this.card});
  final bool available;
  final CardRead? card;
  @override
  Future<bool> get isAvailable async => available;
  @override
  Future<CardRead?> read() async => card;
}

class FakeTextScanner implements TextScanner {
  FakeTextScanner(this.lines);
  final List<String> lines;
  @override
  Future<List<String>> recognise(Uint8List imageBytes) async => lines;
}
