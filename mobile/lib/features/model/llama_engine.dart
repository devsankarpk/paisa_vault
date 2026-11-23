import 'package:llamadart/llamadart.dart';

import '../../services/llm_engine.dart';
import 'model_manifest.dart';

/// The real on-device model, through llamadart (llama.cpp). Settings match the Phase 0 benchmark.
class LlamaDartEngine implements LlmEngine {
  LlamaDartEngine(this._manifest, this._path);

  final ModelManifest _manifest;
  final String _path;
  LlamaEngine? _engine;

  @override
  String get modelId => _manifest.id;

  @override
  Future<void> load() async {
    if (_engine != null) return;
    _engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(_path)),
      params: const ModelParams(
        contextSize: 1024,
        numberOfThreads: 4,
        numberOfThreadsBatch: 6,
      ),
    );
  }

  @override
  Future<String> generate(String prompt) async {
    final engine = _engine;
    if (engine == null) throw StateError('Model not loaded');
    // Qwen3 otherwise writes a long reasoning block first, which is slow and not wanted.
    final text = _manifest.id.startsWith('qwen')
        ? '$prompt\n/no_think'
        : prompt;
    return engine.create([
      LlamaChatMessage.fromText(role: LlamaChatRole.user, text: text),
    ], params: const GenerationParams(maxTokens: 60, temp: 0)).text();
  }

  @override
  Future<void> dispose() async {
    final engine = _engine;
    _engine = null;
    await engine?.dispose();
  }
}
