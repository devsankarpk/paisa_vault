import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_logger.dart';
import '../../core/db/app_database.dart';

/// What the on-device model has been doing, read from model_runs.log. Times and counts only.
class ModelStats {
  const ModelStats({
    required this.answers,
    required this.avgSeconds,
    required this.slowestSeconds,
    required this.loads,
    required this.avgLoadSeconds,
    required this.errors,
    required this.modelMissing,
  });
  final int answers;
  final double avgSeconds;
  final double slowestSeconds;
  final int loads;
  final double avgLoadSeconds;

  /// Error type name to how many times, such as {"TimeoutException": 2}.
  final Map<String, int> errors;
  final int modelMissing;
}

/// Reads the log lines. Anything that does not match is skipped.
ModelStats summariseModelLog(List<String> lines) {
  final seconds = <double>[];
  final loadSeconds = <double>[];
  final errors = <String, int>{};
  var missing = 0;
  final secondsRe = RegExp(r'\b(generated|loaded) seconds=([0-9.]+)');
  final errorRe = RegExp(r'error=([A-Za-z_][A-Za-z0-9_]*)');
  for (final line in lines) {
    final m = secondsRe.firstMatch(line);
    if (m != null) {
      final v = double.tryParse(m.group(2)!);
      if (v != null) (m.group(1) == 'generated' ? seconds : loadSeconds).add(v);
    }
    final e = errorRe.firstMatch(line);
    if (e != null) errors[e.group(1)!] = (errors[e.group(1)!] ?? 0) + 1;
    if (line.contains('model_not_found')) missing++;
  }
  double avg(List<double> l) =>
      l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
  return ModelStats(
    answers: seconds.length,
    avgSeconds: avg(seconds),
    slowestSeconds: seconds.isEmpty
        ? 0
        : seconds.reduce((a, b) => a > b ? a : b),
    loads: loadSeconds.length,
    avgLoadSeconds: avg(loadSeconds),
    errors: errors,
    modelMissing: missing,
  );
}

/// A summary of how the app is doing, with no amounts, merchants, names or message text.
class DiagnosticsReport {
  const DiagnosticsReport({
    required this.generatedAt,
    required this.schemaVersion,
    required this.transactions,
    required this.pleaseConfirm,
    required this.confirmReasons,
    required this.uncategorised,
    required this.corrected,
    required this.messages,
    required this.model,
    required this.crashes,
    required this.lastCrashes,
  });

  final DateTime generatedAt;
  final int schemaVersion;
  final int transactions;
  final int pleaseConfirm;

  /// Reason code to count, such as {"no_model": 3}.
  final Map<String, int> confirmReasons;
  final int uncategorised;

  /// Transactions the user edited by hand: a sign the automatic reading was wrong.
  final int corrected;

  /// Saved messages by state (newMessage, processed, ignored, failed).
  final Map<String, int> messages;
  final ModelStats model;
  final int crashes;
  final List<String> lastCrashes;

  double get pleaseConfirmRate =>
      transactions == 0 ? 0 : pleaseConfirm / transactions;
  double get correctedRate => transactions == 0 ? 0 : corrected / transactions;

  /// Plain text for sharing. Only the numbers and codes above, so it is safe to send.
  String toText() {
    String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
    final b = StringBuffer()
      ..writeln('Paisa Vault diagnostics')
      ..writeln('Made: ${generatedAt.toUtc().toIso8601String()}')
      ..writeln('Database version: $schemaVersion')
      ..writeln()
      ..writeln('Transactions: $transactions')
      ..writeln('Needing a check: $pleaseConfirm (${pct(pleaseConfirmRate)})');
    for (final e in confirmReasons.entries) {
      b.writeln('  reason ${e.key}: ${e.value}');
    }
    b
      ..writeln('Edited by hand: $corrected (${pct(correctedRate)})')
      ..writeln('Without a category: $uncategorised')
      ..writeln()
      ..writeln('Saved messages by state:');
    for (final e in messages.entries) {
      b.writeln('  ${e.key}: ${e.value}');
    }
    b
      ..writeln()
      ..writeln('Model answers: ${model.answers}')
      ..writeln(
        'Seconds per answer: average ${model.avgSeconds.toStringAsFixed(1)}, slowest ${model.slowestSeconds.toStringAsFixed(1)}',
      )
      ..writeln(
        'Model loads: ${model.loads}, average ${model.avgLoadSeconds.toStringAsFixed(1)} s',
      )
      ..writeln('Model file missing: ${model.modelMissing} times');
    for (final e in model.errors.entries) {
      b.writeln('  error ${e.key}: ${e.value}');
    }
    b
      ..writeln()
      ..writeln('Crashes recorded: $crashes');
    for (final c in lastCrashes) {
      b.writeln('  $c');
    }
    // Last line of defence: even if something long slipped in, no long digit runs leave.
    return redact(b.toString());
  }
}

Future<DiagnosticsReport> buildDiagnostics(
  AppDatabase db,
  Directory appSupport,
  DateTime now,
) async {
  final txns = await db.select(db.transactions).get();
  final reasons = <String, int>{};
  var confirm = 0;
  var uncategorised = 0;
  var corrected = 0;
  for (final t in txns) {
    if (t.status == TransactionStatus.pleaseConfirm) {
      confirm++;
      final r = t.confirmReason ?? 'unspecified';
      reasons[r] = (reasons[r] ?? 0) + 1;
    }
    if (t.categoryName == null) uncategorised++;
    if (t.userCorrected) corrected++;
  }
  final messages = <String, int>{};
  for (final m in await db.select(db.rawMessages).get()) {
    messages[m.status.name] = (messages[m.status.name] ?? 0) + 1;
  }
  Future<List<String>> lines(String name, int keep) async {
    final f = File(p.join(appSupport.path, name));
    if (!await f.exists()) return const [];
    final all = await f.readAsLines();
    return all.length > keep ? all.sublist(all.length - keep) : all;
  }

  final crashLines = await lines('crash.log', 500);
  return DiagnosticsReport(
    generatedAt: now,
    schemaVersion: db.schemaVersion,
    transactions: txns.length,
    pleaseConfirm: confirm,
    confirmReasons: reasons,
    uncategorised: uncategorised,
    corrected: corrected,
    messages: messages,
    model: summariseModelLog(await lines('model_runs.log', 2000)),
    crashes: crashLines.length,
    lastCrashes: crashLines.length > 5
        ? crashLines.sublist(crashLines.length - 5)
        : crashLines,
  );
}
