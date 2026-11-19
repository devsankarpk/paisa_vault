import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/key_store.dart';
import '../services/card_reader.dart';
import '../services/llm_engine.dart';
import '../services/sms_source.dart';
import '../services/text_scanner.dart';
import 'clock.dart';
import 'secret_store.dart';

// Real implementations are chosen in main.dart; tests override with fakes.
final clockProvider = Provider<Clock>((_) => const SystemClock());
final smsSourceProvider = Provider<SmsSource>(
  (_) => throw UnimplementedError(),
);
final llmEngineProvider = Provider<LlmEngine>(
  (_) => throw UnimplementedError(),
);
final cardReaderProvider = Provider<CardReader>(
  (_) => throw UnimplementedError(),
);
final textScannerProvider = Provider<TextScanner>(
  (_) => throw UnimplementedError(),
);

final secretStoreProvider = Provider<SecretStore>(
  (_) => throw UnimplementedError(),
);
final keyStoreProvider = Provider<KeyStore>((_) => SecureKeyStore());

/// The encrypted main.db, opened once and closed with the app.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open(ref.watch(keyStoreProvider));
  ref.onDispose(db.close);
  return db;
});
