import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../services/llm_engine.dart';
import '../pipeline/extraction_pipeline.dart';
import 'processing_service.dart';
import 'transaction_repository.dart';

/// The loaded model, or null until the model is installed. Rules run either way.
final activeLlmProvider = Provider<LlmEngine?>((_) => null);

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
  final pipeline = ExtractionPipeline(
    ref.watch(activeLlmProvider),
    categories: defaultCategories,
  );
  return ProcessingService(db, repo, pipeline);
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
