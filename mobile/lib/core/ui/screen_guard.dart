import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Protects the screen while a sensitive page is open: on Android screenshots and screen
/// recordings are blocked and the app switcher shows a blank card; on iPhone the app switcher
/// shows a blurred cover. (Apple gives apps no way to block a screenshot.)
abstract class ScreenGuard {
  Future<void> setProtected(bool on);
}

class NativeScreenGuard implements ScreenGuard {
  static const _channel = MethodChannel('paisa_vault/screen');

  @override
  Future<void> setProtected(bool on) async {
    try {
      await _channel.invokeMethod<void>('setProtected', on);
    } on MissingPluginException {
      // tests and desktop: nothing to protect
    } on PlatformException {
      // keep the app usable if the phone refuses
    }
  }
}

/// Records every change, for tests.
class FakeScreenGuard implements ScreenGuard {
  final changes = <bool>[];
  bool get isOn => changes.isNotEmpty && changes.last;

  @override
  Future<void> setProtected(bool on) async => changes.add(on);
}

final screenGuardProvider = Provider<ScreenGuard>((_) => NativeScreenGuard());

/// Wrap a sensitive page in this. Several can be open at once: protection stays on until the
/// last one closes.
class SecureScreen extends ConsumerStatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  static int _open = 0;

  @override
  ConsumerState<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends ConsumerState<SecureScreen> {
  late final ScreenGuard _guard;

  @override
  void initState() {
    super.initState();
    _guard = ref.read(screenGuardProvider);
    if (++SecureScreen._open == 1) _guard.setProtected(true);
  }

  @override
  void dispose() {
    if (--SecureScreen._open == 0) _guard.setProtected(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
