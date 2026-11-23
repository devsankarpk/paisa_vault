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
  FakeSmsSource({this.granted = true});
  bool granted;
  int permissionRequests = 0;
  final staged = <StagedSms>[];
  final acknowledged = <String>[];
  final _controller = StreamController<void>.broadcast();
  var _n = 0;

  /// Test helper: a message arrives while the app is open.
  void emit(IncomingSms sms) {
    staged.add(StagedSms('id${_n++}', sms));
    _controller.add(null);
  }

  @override
  Stream<void> get arrivals => _controller.stream;
  @override
  Future<bool> get hasPermission async => granted;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<List<StagedSms>> pending() async => List.of(staged);
  @override
  Future<void> acknowledge(List<String> ids) async {
    staged.removeWhere((s) => ids.contains(s.id));
    acknowledged.addAll(ids);
  }
}

class FakeLlmEngine implements LlmEngine {
  /// [replies] are returned in order; the last one repeats. An entry that is an Exception is thrown.
  FakeLlmEngine(this.replies);
  List<Object> replies;
  final prompts = <String>[];
  bool loaded = false;

  @override
  String get modelId => 'fake-model';
  @override
  Future<void> load() async => loaded = true;
  @override
  Future<String> generate(String prompt) async {
    prompts.add(prompt);
    final r = replies[(prompts.length - 1).clamp(0, replies.length - 1)];
    if (r is Exception) throw r;
    return r as String;
  }

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
