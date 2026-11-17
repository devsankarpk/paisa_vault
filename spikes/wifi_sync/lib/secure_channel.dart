import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// One phone's side of an encrypted channel: X25519 key exchange, HKDF key,
/// AES-256-GCM messages, and a 6-digit code both phones can compare.
class SecureChannel {
  SecureChannel._(this._keyPair, this.publicKey);

  final SimpleKeyPair _keyPair;
  final List<int> publicKey;

  static final _x25519 = X25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static Future<SecureChannel> create() async {
    final kp = await _x25519.newKeyPair();
    final pub = await kp.extractPublicKey();
    return SecureChannel._(kp, pub.bytes);
  }

  /// Derives the session for one peer.
  Future<Session> sessionWith(List<int> peerPublicKey) async {
    final secret = await _x25519.sharedSecretKey(
      keyPair: _keyPair,
      remotePublicKey: SimplePublicKey(peerPublicKey, type: KeyPairType.x25519),
    );
    final key = await _hkdf.deriveKey(
      secretKey: secret,
      nonce: utf8.encode('paisavault-spike-v1'),
      info: utf8.encode('message-key'),
    );
    // Code: hash of both public keys in sorted order, so both phones agree.
    final a = base64.encode(publicKey);
    final b = base64.encode(peerPublicKey);
    final ordered = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
    final h = await Sha256().hash(utf8.encode(ordered));
    final n =
        (h.bytes[0] << 24 | h.bytes[1] << 16 | h.bytes[2] << 8 | h.bytes[3]) &
        0x7fffffff;
    final code = (n % 1000000).toString().padLeft(6, '0');
    return Session(key, code);
  }
}

class Session {
  Session(this._key, this.code);
  final SecretKey _key;
  final String code;

  Future<Map<String, String>> encrypt(String text) async {
    final box = await SecureChannel._aes.encryptString(text, secretKey: _key);
    return {
      'nonce': base64.encode(box.nonce),
      'ct': base64.encode(box.cipherText),
      'mac': base64.encode(box.mac.bytes),
    };
  }

  Future<String> decrypt(Map<String, dynamic> m) async {
    final box = SecretBox(
      base64.decode(m['ct'] as String),
      nonce: base64.decode(m['nonce'] as String),
      mac: Mac(base64.decode(m['mac'] as String)),
    );
    return SecureChannel._aes.decryptString(box, secretKey: _key);
  }
}
