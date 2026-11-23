import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../services/llm_engine.dart';
import '../pipeline/model_reply.dart';
import '../model/llama_engine.dart';
import '../model/model_diagnostics.dart';
import '../model/model_locator.dart';
import '../model/model_manifest.dart';
import 'processing_service.dart';
import 'transaction_repository.dart';

final modelLocatorProvider = Provider<ModelLocator>(
  (_) => AppFolderModelLocator(),
);

/// Loads the model if one is installed, else null. Called only when messages are waiting.
final engineFactoryProvider = Provider<Future<LlmEngine?> Function()>((ref) {
  final diag = ModelDiagnostics();
  return () async {
    final path = await ref.read(modelLocatorProvider).find(qwen3Manifest);
    if (path == null) {
      await diag.note('model_not_found');
      return null;
    }
    final watch = Stopwatch()..start();
    final engine = LlamaDartEngine(qwen3Manifest, path);
    try {
      await engine.load();
    } catch (e) {
      await diag.note('load_failed error=${e.runtimeType}');
      rethrow;
    }
    await diag.note(
      'loaded seconds=${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}',
    );
    return _TimedEngine(engine, diag);
  };
});

/// Wraps the engine to record how long each answer took and whether it failed.
class _TimedEngine implements LlmEngine {
  _TimedEngine(this._inner, this._diag);
  final LlmEngine _inner;
  final ModelDiagnostics _diag;

  @override
  String get modelId => _inner.modelId;
  @override
  Future<void> load() => _inner.load();
  @override
  Future<String> generate(String prompt) async {
    final watch = Stopwatch()..start();
    try {
      final reply = await _inner.generate(prompt);
      await _diag.note(
        'generated seconds=${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} chars=${reply.length} ${_shape(reply)}',
      );
      return reply;
    } catch (e) {
      await _diag.note('generate_failed error=${e.runtimeType}');
      rethrow;
    }
  }

  /// Describes the reply's shape without its text: which keys, and whether the category and
  /// channel are on the allowed lists. Used to see why a reply was rejected.
  static String _shape(String r) {
    final keys = RegExp(r'"(\w+)"\s*:')
        .allMatches(r)
        .map((m) => m[1])
        .join('/');
    String? val(String k) =>
        RegExp('"$k"\\s*:\\s*"([^"]*)"').firstMatch(r)?.group(1);
    final cat = val('category');
    final ch = val('channel');
    return 'think=${r.contains('<think>')} fence=${r.contains('```')} '
        'start=${r.trimLeft().startsWith('{')} keys=$keys '
        'catOk=${cat == null ? 'none' : defaultCategories.contains(cat)} '
        'chOk=${ch == null ? 'none' : allowedChannels.contains(ch)}';
  }

  @override
  Future<void> dispose() async {
    await _inner.dispose();
    await _diag.note('freed');
  }
}

final transactionRepositoryProvider = FutureProvider<TransactionRepository>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return TransactionRepository(db, ref.watch(clockProvider));
});

final processingServiceProvider = FutureProvider<ProcessingService>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final repo = await ref.watch(transactionRepositoryProvider.future);
  return ProcessingService(
    db,
    repo,
    categories: defaultCategories,
    engineFactory: ref.watch(engineFactoryProvider),
    log: (e) => ModelDiagnostics().note(e),
  );
});

final transactionsProvider = StreamProvider<List<Transaction>>((ref) async* {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  yield* repo.watchAll();
});

final transactionProvider = StreamProvider.family<Transaction?, int>((
  ref,
  id,
) async* {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  yield* repo.watchOne(id);
});

/// The original message behind a transaction, read only when its detail screen is open.
final originalMessageProvider = FutureProvider.family<String?, int>((
  ref,
  id,
) async {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  final t = await ref.watch(transactionProvider(id).future);
  if (t == null) return null;
  return (await repo.rawMessageFor(t))?.body;
});
