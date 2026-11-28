import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../lock/lock_controller.dart';
import 'card_secret_store.dart';
import 'hide_service.dart';
import 'vault_key_service.dart';
import 'vault_session.dart';

final vaultKeyServiceProvider = Provider<VaultKeyService>(
  (ref) => VaultKeyService(ref.watch(secretStoreProvider)),
);

/// The private vault. Locked until the owner opens it, and locked again whenever the app locks.
final vaultSessionProvider = FutureProvider<VaultSession>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final session = VaultSession(
    file: File(p.join(dir.path, 'vault.db')),
    keys: ref.watch(vaultKeyServiceProvider),
    pin: ref.watch(pinServiceProvider),
    biometrics: ref.watch(biometricsProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(session.lock);
  return session;
});

final cardSecretStoreProvider = FutureProvider<CardSecretStore>((ref) async {
  return CardSecretStore(
    await ref.watch(vaultSessionProvider.future),
    ref.watch(clockProvider),
  );
});

final hideServiceProvider = FutureProvider<HideService>((ref) async {
  return HideService(
    await ref.watch(appDatabaseProvider.future),
    await ref.watch(vaultSessionProvider.future),
    ref.watch(clockProvider),
  );
});
