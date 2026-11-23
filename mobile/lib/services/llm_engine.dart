/// On-device model behind an interface so it can be swapped (ADR 0001).
///
/// The engine only turns a prompt into text. The pipeline builds the prompt and checks the
/// reply, so the same code works with any model and with a fake in tests.
abstract class LlmEngine {
  /// Identifies the model and quantisation, stored on each transaction.
  String get modelId;

  Future<void> load();

  /// Returns the model's raw text reply. Throws if the model is not loaded or fails.
  Future<String> generate(String prompt);

  Future<void> dispose();
}
