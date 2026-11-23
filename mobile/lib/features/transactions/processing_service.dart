import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../services/llm_engine.dart';
import '../pipeline/extraction_pipeline.dart';
import 'transaction_repository.dart';

class ProcessingResult {
  const ProcessingResult({required this.transactions, required this.skipped});
  final int transactions;
  final int skipped;
}

/// Turns saved messages marked "new" into transactions. A message that gives no amount or
/// direction is marked ignored so it is not tried again.
class ProcessingService {
  ProcessingService(
    this._db,
    this._repo, {
    required this.categories,
    this.engineFactory,
    this.log,
  });
  final AppDatabase _db;
  final TransactionRepository _repo;
  final List<String> categories;

  /// Gives a loaded model, or null when none is installed. Called only when messages are waiting,
  /// and the model is freed after each batch so it does not hold memory between batches.
  final Future<LlmEngine?> Function()? engineFactory;

  /// Optional diagnostics: short event lines with counts and error types, never message text.
  final void Function(String event)? log;
  bool _running = false;

  Future<ProcessingResult> processNew() async {
    if (_running) return const ProcessingResult(transactions: 0, skipped: 0);
    _running = true;
    try {
      final pending =
          await (_db.select(_db.rawMessages)
                ..where(
                  (m) => m.status.equals(RawMessageStatus.newMessage.name),
                )
                ..orderBy([(m) => OrderingTerm.asc(m.receivedAt)]))
              .get();
      // Transactions made while no model was installed can be re-checked once one is.
      final recheck =
          await (_db.select(_db.transactions)..where(
                (t) =>
                    t.confirmReason.isIn(const [
                      'no_model',
                      'bad_reply',
                      'model_error',
                    ]) &
                    t.userCorrected.equals(false) &
                    t.rawMessageId.isNotNull(),
              ))
              .get();
      if (log != null) {
        final all = await _db.select(_db.transactions).get();
        final reasons = <String, int>{};
        for (final t in all) {
          final key =
              '${t.status.name}/${t.confirmReason ?? 'none'}/${t.userCorrected ? 'corrected' : 'untouched'}';
          reasons[key] = (reasons[key] ?? 0) + 1;
        }
        log!(
          'process pending=${pending.length} recheck=${recheck.length} total=${all.length} states=$reasons',
        );
      }
      if (pending.isEmpty && recheck.isEmpty) {
        return const ProcessingResult(transactions: 0, skipped: 0);
      }
      LlmEngine? engine;
      try {
        engine = await engineFactory?.call();
      } catch (e) {
        log?.call('engine_factory_failed error=${e.runtimeType}');
        engine = null; // the model could not load: rules only, transactions say please confirm
      }
      final pipeline = ExtractionPipeline(engine, categories: categories);
      try {
        var made = 0;
        var skipped = 0;
        for (final m in pending) {
          final result = await pipeline.process(m.body);
          final t = result.transaction;
          if (t == null) {
            skipped++;
            await _mark(m.id, RawMessageStatus.ignored);
            continue;
          }
          await _db.transaction(() async {
            await _repo.insertExtracted(
              t,
              rawMessageId: m.id,
              receivedAt: m.receivedAt,
            );
            await _mark(m.id, RawMessageStatus.processed);
          });
          made++;
        }
        if (engine != null) {
          for (final t in recheck) {
            await _recheck(t, pipeline);
          }
        }
        return ProcessingResult(transactions: made, skipped: skipped);
      } finally {
        await engine?.dispose();
      }
    } finally {
      _running = false;
    }
  }

  /// Fills in merchant, category and channel from the model. Amount, direction and the other rule
  /// fields stay as they were, and nothing the user has corrected is touched (filtered above).
  Future<void> _recheck(Transaction t, ExtractionPipeline pipeline) async {
    final raw = await (_db.select(
      _db.rawMessages,
    )..where((m) => m.id.equals(t.rawMessageId!))).getSingleOrNull();
    if (raw == null) return;
    final fresh = (await pipeline.process(raw.body)).transaction;
    // Only accept the result if the model actually answered; otherwise try again next time.
    if (fresh == null || fresh.confirmReason == 'model_error') return;
    await (_db.update(_db.transactions)..where((x) => x.id.equals(t.id))).write(
      TransactionsCompanion(
        merchant: Value(fresh.merchant ?? t.merchant),
        categoryName: Value(fresh.category ?? t.categoryName),
        channel: Value(fresh.channel ?? t.channel),
        status: Value(fresh.status),
        confirmReason: Value(fresh.confirmReason),
        modelId: Value(fresh.modelId),
        promptVersion: Value(fresh.promptVersion),
      ),
    );
  }

  Future<void> _mark(int id, RawMessageStatus status) =>
      (_db.update(_db.rawMessages)..where((m) => m.id.equals(id))).write(
        RawMessagesCompanion(status: Value(status)),
      );
}
