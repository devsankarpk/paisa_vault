import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PaisaVaultSms") {
      SmsChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PaisaVaultScreen") {
      ScreenGuard.register(messenger: registrar.messenger())
    }
  }
}

/// While a sensitive page is open, covers the app with a blur whenever it is not active, so the
/// app switcher never shows card details. iOS offers no way to block screenshots.
final class ScreenGuard {
  private static var protected = false
  private static var cover: UIView?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "paisa_vault/screen", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "setProtected" {
        protected = (call.arguments as? Bool) ?? false
        if !protected { hide() }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    let nc = NotificationCenter.default
    nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
      if protected { show() }
    }
    nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
      hide()
    }
  }

  private static func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private static func show() {
    guard cover == nil, let window = keyWindow() else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(blur)
    cover = blur
  }

  private static func hide() {
    cover?.removeFromSuperview()
    cover = nil
  }
}
