import AppIntents
import Foundation

/// Shortcuts action "Log Bank Message". The Shortcuts automation passes in the SMS text.
/// Bank-looking messages go into the encrypted stage (SmsStage.swift); the text is never logged
/// and never leaves the phone.
@available(iOS 16.0, *)
struct LogBankMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Bank Message"
  static var description = IntentDescription(
    "Saves a bank SMS inside Paisa Vault on this phone. Nothing is uploaded.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Message")
  var message: String

  func perform() async throws -> some IntentResult {
    // Diagnostics: time, length, kept flag and error type only. Never the message text.
    let kept = SmsFilter.looksLikeBankMessage(message)
    var failure = "none"
    if kept {
      do { try SmsStage.add(body: message) } catch { failure = String(describing: type(of: error)) }
    }
    SmsStage.noteRun(length: message.count, kept: kept, failure: failure)
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
