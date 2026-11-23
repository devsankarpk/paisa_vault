/// Describes the on-device model the app expects. Kept in code (not a downloaded file) so a
/// build always knows exactly which model, licence and prompt it was tested with.
class ModelManifest {
  const ModelManifest({
    required this.id,
    required this.fileName,
    required this.licence,
    required this.source,
    this.sha256,
  });

  /// Stored on each transaction (model_id).
  final String id;

  /// File name inside the app's model folder.
  final String fileName;
  final String licence;
  final String source;

  /// Expected SHA-256 of the file, once the exact release is pinned (ADR 0001 open check).
  final String? sha256;
}

/// Working model from ADR 0001 (status: proposed).
const qwen3Manifest = ModelManifest(
  id: 'qwen3-1.7b-q4',
  fileName: 'qwen3-1.7b-q4.gguf',
  licence: 'Apache-2.0',
  source: 'Qwen3 1.7B, GGUF int4',
);
