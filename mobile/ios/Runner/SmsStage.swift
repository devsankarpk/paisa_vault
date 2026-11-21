import CryptoKit
import Flutter
import Foundation
import Security

/// Loose pre-filter, same rules as SmsFilter.kt on Android: keep a message only when it has an
/// amount and a money-movement word. The precise filter runs later in Dart.
enum SmsFilter {
  private static let amount = try! NSRegularExpression(pattern: "(rs\\.?|inr|₹)\\s*[\\d,]+(\\.\\d+)?", options: .caseInsensitive)
  private static let movement = try! NSRegularExpression(
    pattern: "\\b(debited|credited|debit|credit|spent|paid|withdrawn|received|sent|purchase|txn|transaction|payment)\\b",
    options: .caseInsensitive)
  private static let otp = try! NSRegularExpression(
    pattern: "\\b(otp|one[- ]time password|verification code)\\b", options: .caseInsensitive)
  private static let strong = try! NSRegularExpression(
    pattern: "\\b(debited|credited|spent|withdrawn)\\b", options: .caseInsensitive)

  private static func has(_ r: NSRegularExpression, _ s: String) -> Bool {
    r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
  }

  static func looksLikeBankMessage(_ body: String) -> Bool {
    if !has(amount, body) || !has(movement, body) { return false }
    if has(otp, body) && !has(strong, body) { return false }
    return true
  }
}

struct StagedMessage {
  let id: String
  let body: String
  let receivedAtMillis: Int64
}

/// Encrypted holding area for messages the Shortcut sends while the app is closed. The key is a
/// random 256-bit value in the Keychain (available after first unlock). Message text is never
/// logged. The Flutter side drains it into the encrypted database after unlock.
enum SmsStage {
  private static let keyAccount = "pv_sms_stage_key"
  private static let lock = NSLock()  // only guards the diagnostics log

  private static var baseURL: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
  }

  /// One small encrypted file per message, written atomically. No appending or rewriting, so two
  /// Shortcut runs at once (a message that matches two keywords) cannot overwrite each other.
  private static var dirURL: URL {
    let dir = baseURL.appendingPathComponent("sms_stage", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private static func key() throws -> SymmetricKey {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: keyAccount,
      kSecReturnData as String: true,
    ]
    var out: AnyObject?
    if SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess, let data = out as? Data {
      return SymmetricKey(data: data)
    }
    let fresh = SymmetricKey(size: .bits256)
    let data = fresh.withUnsafeBytes { Data($0) }
    let add: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: keyAccount,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else {
      throw NSError(domain: "PaisaVault", code: 1)
    }
    return fresh
  }

  static func add(body: String) throws {
    let record: [String: Any] = [
      "body": body,
      "at": Int64(Date().timeIntervalSince1970 * 1000),
    ]
    let json = try JSONSerialization.data(withJSONObject: record)
    let sealed = try AES.GCM.seal(json, using: try key()).combined!
    let name = "\(Int64(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString).msg"
    try sealed.write(
      to: dirURL.appendingPathComponent(name),
      options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  /// One line per intent run, for diagnosing the Shortcut route. Holds no message text.
  static func noteRun(length: Int, kept: Bool, failure: String) {
    lock.lock(); defer { lock.unlock() }
    let url = baseURL.appendingPathComponent("intent_runs.log")
    let line = "\(ISO8601DateFormatter().string(from: Date())) length=\(length) kept=\(kept) error=\(failure)\n"
    if let h = try? FileHandle(forWritingTo: url) {
      defer { try? h.close() }
      _ = try? h.seekToEnd()
      try? h.write(contentsOf: Data(line.utf8))
    } else {
      try? line.write(to: url, atomically: true, encoding: .utf8)
    }
  }

  static func pending() -> [StagedMessage] {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: dirURL.path),
      let k = try? key()
    else { return [] }
    var out: [StagedMessage] = []
    for name in names.sorted() where name.hasSuffix(".msg") {
      guard let raw = try? Data(contentsOf: dirURL.appendingPathComponent(name)),
        let box = try? AES.GCM.SealedBox(combined: raw),
        let plain = try? AES.GCM.open(box, using: k),
        let obj = try? JSONSerialization.jsonObject(with: plain) as? [String: Any],
        let body = obj["body"] as? String, let at = obj["at"] as? NSNumber
      else { continue }
      out.append(StagedMessage(id: name, body: body, receivedAtMillis: at.int64Value))
    }
    return out
  }

  static func acknowledge(_ ids: Set<String>) {
    for id in ids where !id.contains("/") {
      try? FileManager.default.removeItem(at: dirURL.appendingPathComponent(id))
    }
  }
}

/// Same channel contract as Android (MainActivity.kt) so the Dart side is shared.
enum SmsChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "paisa_vault/sms", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hasPermission", "requestPermission":
        result(true)  // iPhone needs no SMS permission; the Shortcut does the work.
      case "pending":
        result(
          SmsStage.pending().map {
            ["id": $0.id, "sender": "", "body": $0.body, "receivedAt": $0.receivedAtMillis, "sub": -1]
          })
      case "acknowledge":
        let args = call.arguments as? [String: Any]
        SmsStage.acknowledge(Set((args?["ids"] as? [String]) ?? []))
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
