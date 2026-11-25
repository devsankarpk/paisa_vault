import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';

/// Local crash capture. Nothing leaves the phone; the owner can read the file for diagnosis.
///
/// An error's message is never written: it can contain text from an SMS (for example a parse
/// error quoting its input). Only the error type and the first lines of the stack are kept, and
/// the stack lines hold file names and line numbers only.
class CrashLog {
  CrashLog([Future<Directory> Function()? base])
    : _base = base ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _base;

  static const fileName = 'crash.log';
  static const maxBytes = 64 * 1024;
  static const stackLines = 6;

  /// One line for the log, without the error's message.
  static String describe(Object error, StackTrace? stack, DateTime when) {
    final frames = (stack?.toString() ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(stackLines)
        .map((l) => redact(l.trim()))
        .join(' | ');
    return '${when.toUtc().toIso8601String()} crash type=${error.runtimeType} at $frames';
  }

  Future<void> record(Object error, StackTrace? stack) async {
    try {
      final file = File(p.join((await _base()).path, fileName));
      // Keep the file small: when it gets big, start again.
      if (await file.exists() && await file.length() > maxBytes) {
        await file.delete();
      }
      await file.writeAsString(
        '${describe(error, stack, DateTime.now())}\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Capturing a crash must never cause another one.
    }
  }

  /// Sends uncaught errors to the log, then on to the previous handler (red screen, console).
  void install() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack);
      previousFlutter?.call(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      return previousPlatform?.call(error, stack) ?? false;
    };
  }
}
