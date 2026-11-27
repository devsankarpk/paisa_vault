import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import 'erase_service.dart';

/// Erases everything on this phone and closes the database. The caller then reloads the lock
/// state so the app starts like a fresh install.
Future<void> eraseEverything(WidgetRef ref) async {
  final db = await ref.read(appDatabaseProvider.future);
  await EraseService(
    appSupport: await getApplicationSupportDirectory(),
    keyStore: ref.read(keyStoreProvider),
    secrets: ref.read(secretStoreProvider),
    sms: ref.read(smsSourceProvider),
    closeDatabase: db.close,
  ).eraseAll();
  ref.invalidate(appDatabaseProvider);
}
