import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/db/key_store.dart';
import '../../core/secret_store.dart';
import '../../services/sms_source.dart';

/// "Erase everything": deletes the database and its key, the PIN and lock settings, saved
/// messages still waiting to be read, and the diagnostic logs. The app then starts like a
/// fresh install. The model file is not personal data and stays.
class EraseService {
  EraseService({
    required this.appSupport,
    required this.keyStore,
    required this.secrets,
    required this.sms,
    required this.closeDatabase,
  });

  final Directory appSupport;
  final KeyStore keyStore;
  final SecretStore secrets;
  final SmsSource sms;
  final Future<void> Function() closeDatabase;

  /// Everything the app keeps in the secret store.
  static const secretKeys = [
    'pv_pin_hash',
    'pv_pin_salt',
    'pv_pin_fails',
    'pv_pin_lock_until',
    'pv_bio_enabled',
    'pv_autolock_secs',
    'pv_sms_disclosure_seen',
    'pv_shortcut_guide_seen',
  ];

  static const files = [
    'main.db',
    'main.db-wal',
    'main.db-shm',
    'main.db-journal',
    'model_runs.log',
    'intent_runs.log',
    'crash.log',
  ];

  Future<void> eraseAll() async {
    await closeDatabase();
    for (final name in files) {
      final f = File(p.join(appSupport.path, name));
      if (await f.exists()) await f.delete();
    }
    await keyStore.delete('main');
    for (final k in secretKeys) {
      await secrets.delete(k);
    }
    // Messages the phone saved for us but the app has not read yet.
    final staged = await sms.pending();
    if (staged.isNotEmpty) {
      await sms.acknowledge(staged.map((m) => m.id).toList());
    }
  }
}
