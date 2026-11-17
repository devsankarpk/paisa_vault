import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the database key. The key lives in the Android Keystore / iOS Keychain,
/// never in the app's files.
abstract class KeyStore {
  /// Returns the stored key for [name], creating a random 256-bit one on first use.
  Future<List<int>> keyFor(String name);

  /// Deletes the key (used by "Erase everything"). The database becomes unreadable.
  Future<void> delete(String name);
}

List<int> randomKey([Random? random]) {
  final r = random ?? Random.secure();
  return List<int>.generate(32, (_) => r.nextInt(256));
}

class SecureKeyStore implements KeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            // Available after first unlock so background SMS processing can open the DB.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<List<int>> keyFor(String name) async {
    final id = 'pv_db_key_$name';
    final existing = await _storage.read(key: id);
    if (existing != null) return base64Decode(existing);
    final key = randomKey();
    await _storage.write(key: id, value: base64Encode(key));
    return key;
  }

  @override
  Future<void> delete(String name) => _storage.delete(key: 'pv_db_key_$name');
}

/// For tests only.
class MemoryKeyStore implements KeyStore {
  final _keys = <String, List<int>>{};

  @override
  Future<List<int>> keyFor(String name) async =>
      _keys.putIfAbsent(name, randomKey);

  @override
  Future<void> delete(String name) async => _keys.remove(name);
}
