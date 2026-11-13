import AppIntents
import Foundation

/// Shortcuts action "Log Bank Message". The Shortcuts automation passes in the SMS text.
/// Spike only: appends one JSON line to Documents/shortcut_inbox.jsonl inside the app sandbox.
/// The text is never logged to the system log and never leaves the phone.
@available(iOS 16.0, *)
struct LogBankMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Bank Message"
  static var description = IntentDescription(
    "Saves a bank SMS inside Paisa Vault on this phone. Nothing is uploaded.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Message")
  var message: String

  func perform() async throws -> some IntentResult {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let file = docs.appendingPathComponent("shortcut_inbox.jsonl")
    let record: [String: Any] = [
      "received_at": ISO8601DateFormatter().string(from: Date()),
      "length": message.count,
      "body": message,
    ]
    let data = try JSONSerialization.data(withJSONObject: record)
    var line = data
    line.append(0x0A)
    if let handle = try? FileHandle(forWritingTo: file) {
      defer { try? handle.close() }
      try handle.seekToEnd()
      try handle.write(contentsOf: line)
    } else {
      try line.write(to: file, options: .atomic)
    }
    return .result()
  }
}

@available(iOS 16.4, *)
struct PaisaVaultShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LogBankMessageIntent(),
      phrases: ["Log bank message in \(.applicationName)"],
      shortTitle: "Log Bank Message",
      systemImageName: "tray.and.arrow.down")
  }
}
