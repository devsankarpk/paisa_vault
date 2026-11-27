import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../services/llm_engine.dart';
import '../pipeline/extraction_pipeline.dart';
import '../pipeline/prompt.dart';
import '../sms/sms_classifier.dart';
import 'transaction_repository.dart';

class ProcessingResult {
  const ProcessingResult({
    required this.transactions,
    required this.skipped,
    this.duplicates = 0,
  });
  final int transactions;
  final int skipped;

  /// Messages for a transaction that was already stored.
  final int duplicates;
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
      await _reclassifyIfNeeded();
      final extra = await _repo.removeSameTextDuplicates();
      if (extra > 0) log?.call('duplicates_removed=$extra');
      final pending =
          await (_db.select(_db.rawMessages)
                ..where(
                  (m) => m.status.equals(RawMessageStatus.newMessage.name),
                )
                ..orderBy([(m) => OrderingTerm.asc(m.receivedAt)]))
              .get();
      // Transactions made while no model was installed can be re-checked once one is.
      await _repo.refillRuleFields();
      await _repo.linkUnlinked();
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
        var duplicates = 0;
        for (final m in pending) {
          // The same text was already turned into a transaction: no need to read it again.
          if (await _repo.sameTextAlreadyCounted(m)) {
            await _mark(m.id, RawMessageStatus.processed);
            duplicates++;
            continue;
          }
          final result = await pipeline.process(m.body);
          final t = result.transaction;
          if (t == null) {
            skipped++;
            await _mark(m.id, RawMessageStatus.ignored);
            continue;
          }
          var duplicate = false;
          await _db.transaction(() async {
            final id = await _repo.insertExtracted(
              t,
              rawMessageId: m.id,
              receivedAt: m.receivedAt,
            );
            duplicate = id == null;
            await _mark(m.id, RawMessageStatus.processed);
          });
          if (duplicate) {
            duplicates++;
          } else {
            made++;
          }
        }
        if (engine != null) {
          for (final t in recheck) {
            await _recheck(t, pipeline);
          }
        }
        return ProcessingResult(
          transactions: made,
          skipped: skipped,
          duplicates: duplicates,
        );
      } finally {
        await engine?.dispose();
      }
    } finally {
      _running = false;
    }
  }

  static const _versionKey = 'classifier_version';

  /// After the rules improve, messages set aside earlier as reminders or "other" are looked at
  /// once more. Any that now count as a transaction go back in the queue. Runs once per version.
  /// Returns how many were put back.
  Future<int> _reclassifyIfNeeded() async {
    final stored = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_versionKey))).getSingleOrNull();
    if (int.tryParse(stored?.value ?? '') == classifierVersion) return 0;
    final ignored = await (_db.select(
      _db.rawMessages,
    )..where((m) => m.status.equals(RawMessageStatus.ignored.name))).get();
    var back = 0;
    final removed =
        await _repo.removeSameTextDuplicates() +
        await _repo.removeLookalikeDuplicates();
    for (final m in ignored) {
      final kind = const SmsClassifier()
          .classify(m.body, sender: m.sender)
          .kind;
      if (kind != SmsKind.transaction) continue;
      final has = await (_db.select(
        _db.transactions,
      )..where((t) => t.rawMessageId.equals(m.id))).get();
      if (has.isNotEmpty) continue;
      await _mark(m.id, RawMessageStatus.newMessage);
      back++;
    }
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            key: _versionKey,
            value: '$classifierVersion',
          ),
          onConflict: DoUpdate(
            (_) => SettingsCompanion(value: Value('$classifierVersion')),
            target: [_db.settings.key],
          ),
        );
    log?.call('reclassified back=$back duplicates_removed=$removed');
    return back;
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
    final merchant = fresh.merchant ?? t.merchant;
    final category = await _repo.categorise(
      merchant,
      t.direction,
      fresh.category,
    );
    await (_db.update(_db.transactions)..where((x) => x.id.equals(t.id))).write(
      TransactionsCompanion(
        merchant: Value(merchant),
        categoryName: Value(category ?? t.categoryName),
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

  /// Re-reads recent transactions with the current model and returns what would change, so the
  /// user can confirm instead of the app overwriting silently. Looks only at transactions the
  /// user has not edited, whose message is still saved and which an older model or prompt made.
  /// Those with no difference are marked as checked straight away. Returns null when no model is
  /// available or messages are being processed right now.
  Future<List<RecheckChange>?> previewRecheck({
    int limit = 20,
    void Function(int done, int total)? progress,
  }) async {
    if (_running) return null;
    _running = true;
    LlmEngine? engine;
    try {
      try {
        engine = await engineFactory?.call();
      } catch (_) {
        engine = null;
      }
      if (engine == null) return null;
      final pipeline = ExtractionPipeline(engine, categories: categories);
      final all =
          await (_db.select(_db.transactions)
                ..where(
                  (t) =>
                      t.userCorrected.equals(false) &
                      t.rawMessageId.isNotNull(),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
              .get();
      final due = all
          .where(
            (t) =>
                t.modelId != engine!.modelId ||
                t.promptVersion != promptVersion,
          )
          .take(limit)
          .toList();
      final changes = <RecheckChange>[];
      for (var i = 0; i < due.length; i++) {
        progress?.call(i, due.length);
        final t = due[i];
        final raw = await (_db.select(
          _db.rawMessages,
        )..where((m) => m.id.equals(t.rawMessageId!))).getSingleOrNull();
        if (raw == null) continue; // the message was purged
        final fresh = (await pipeline.process(raw.body)).transaction;
        if (fresh == null || fresh.confirmReason == 'model_error') continue;
        final merchant = fresh.merchant ?? t.merchant;
        final category =
            await _repo.categorise(merchant, t.direction, fresh.category) ??
            t.categoryName;
        final channel = fresh.channel ?? t.channel;
        final change = RecheckChange(
          transactionId: t.id,
          oldMerchant: t.merchant,
          newMerchant: merchant,
          oldCategory: t.categoryName,
          newCategory: category,
          oldChannel: t.channel,
          newChannel: channel,
          status: fresh.status,
          confirmReason: fresh.confirmReason,
          modelId: fresh.modelId,
          promptVersion: fresh.promptVersion,
        );
        if (change.differs) {
          changes.add(change);
        } else {
          await _writeRecheck(change, fields: false);
        }
      }
      progress?.call(due.length, due.length);
      return changes;
    } finally {
      await engine?.dispose();
      _running = false;
    }
  }

  /// Applies the changes the user accepted.
  Future<void> applyRecheck(Iterable<RecheckChange> changes) async {
    for (final c in changes) {
      await _writeRecheck(c, fields: true);
    }
  }

  Future<void> _writeRecheck(RecheckChange c, {required bool fields}) =>
      (_db.update(
        _db.transactions,
      )..where((x) => x.id.equals(c.transactionId))).write(
        TransactionsCompanion(
          merchant: fields ? Value(c.newMerchant) : const Value.absent(),
          categoryName: fields ? Value(c.newCategory) : const Value.absent(),
          channel: fields ? Value(c.newChannel) : const Value.absent(),
          status: fields ? Value(c.status) : const Value.absent(),
          confirmReason: fields ? Value(c.confirmReason) : const Value.absent(),
          modelId: Value(c.modelId),
          promptVersion: Value(c.promptVersion),
        ),
      );
}

/// What a newer model would change on one transaction.
class RecheckChange {
  const RecheckChange({
    required this.transactionId,
    required this.oldMerchant,
    required this.newMerchant,
    required this.oldCategory,
    required this.newCategory,
    required this.oldChannel,
    required this.newChannel,
    required this.status,
    required this.confirmReason,
    required this.modelId,
    required this.promptVersion,
  });
  final int transactionId;
  final String? oldMerchant, newMerchant;
  final String? oldCategory, newCategory;
  final String? oldChannel, newChannel;
  final TransactionStatus status;
  final String? confirmReason;
  final String? modelId;
  final String? promptVersion;

  bool get differs =>
      oldMerchant != newMerchant ||
      oldCategory != newCategory ||
      oldChannel != newChannel;
}
