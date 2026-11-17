/// Fields the model returns. The amount is checked against the SMS text later.
class LlmExtraction {
  const LlmExtraction({this.merchant, this.category, this.channel});

  final String? merchant;
  final String? category;
  final String? channel;
}

/// On-device model behind an interface so it can be swapped (ADR 0001).
abstract class LlmEngine {
  Future<void> load();
  Future<LlmExtraction> extract(
    String smsText, {
    required List<String> categories,
  });
  Future<void> dispose();
}
