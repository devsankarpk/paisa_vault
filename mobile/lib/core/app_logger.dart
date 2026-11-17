import 'package:logging/logging.dart';

/// Matches 5 or more digits in a row, and SMS-looking text is never passed in
/// at all. This is the last line of defence, not a licence to log message text.
final _longDigits = RegExp(r'\d{5,}');

String redact(String message) => message.replaceAll(_longDigits, '<redacted>');

/// App logger. Callers log events and ids, never SMS bodies or card numbers.
class AppLogger {
  AppLogger(String name) : _log = Logger(name);
  final Logger _log;

  void info(String message) => _log.info(redact(message));
  void warning(String message) => _log.warning(redact(message));
  void error(String message, [Object? error]) =>
      _log.severe(redact(message), error == null ? null : redact('$error'));
}
