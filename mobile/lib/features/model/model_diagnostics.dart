import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_logger.dart';

/// One line per model event in a local file, for diagnosing the on-device model. Holds times,
/// short event codes, durations and error types only. Never message text.
class ModelDiagnostics {
  ModelDiagnostics([Future<Directory> Function()? base])
    : _base = base ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _base;

  Future<void> note(String event) async {
    try {
      final file = File(p.join((await _base()).path, 'model_runs.log'));
      await file.writeAsString(
        '${DateTime.now().toUtc().toIso8601String()} ${redact(event)}\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Diagnostics must never break processing.
    }
  }
}
