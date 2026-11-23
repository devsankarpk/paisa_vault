import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
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
  ProcessingService(this._db, this._repo, this._pipeline);
  final AppDatabase _db;
  final TransactionRepository _repo;
  final ExtractionPipeline _pipeline;
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
      var made = 0;
      var skipped = 0;
      for (final m in pending) {
        final result = await _pipeline.process(m.body);
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
      return ProcessingResult(transactions: made, skipped: skipped);
    } finally {
      _running = false;
    }
  }

  Future<void> _mark(int id, RawMessageStatus status) =>
      (_db.update(_db.rawMessages)..where((m) => m.id.equals(id))).write(
        RawMessagesCompanion(status: Value(status)),
      );
}
