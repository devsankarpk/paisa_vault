import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// How many raw messages are saved. A number only, never message text.
final savedMessageCountProvider = StreamProvider<int>((ref) async* {
  final db = await ref.watch(appDatabaseProvider.future);
  final count = db.rawMessages.id.count();
  final query = db.selectOnly(db.rawMessages)..addColumns([count]);
  yield* query.map((row) => row.read(count) ?? 0).watchSingle();
});

/// Receive times of saved messages (times only, never text), newest first. For checking.
final savedTimesProvider = StreamProvider<List<DateTime>>((ref) async* {
  final db = await ref.watch(appDatabaseProvider.future);
  final q = db.select(db.rawMessages)
    ..orderBy([(m) => OrderingTerm.desc(m.receivedAt)])
    ..limit(10);
  yield* q.watch().map((rows) => [for (final r in rows) r.receivedAt]);
});
