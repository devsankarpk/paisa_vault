import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_controller.dart';
import 'lock_screens.dart';

/// Shows [child] only while unlocked. Locks after the idle time and when the app has been
/// in the background for that long, and hides content in the app switcher.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool _inactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Every touch anywhere in the app (including pushed screens and sheets, which sit
    // above this widget) counts as activity and restarts the idle timer.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    Future.microtask(() => ref.read(lockControllerProvider.notifier).load());
  }

  void _onPointer(PointerEvent e) {
    if (e is PointerDownEvent || e is PointerUpEvent) {
      ref.read(lockControllerProvider.notifier).touch();
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = ref.read(lockControllerProvider.notifier);
    setState(() => _inactive = state != AppLifecycleState.resumed);
    if (state == AppLifecycleState.paused) {
      c.appBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      c.appResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(lockControllerProvider.select((s) => s.status));
    final body = switch (status) {
      LockStatus.loading => const Scaffold(body: SizedBox.shrink()),
      LockStatus.needsSetup => const SetupScreen(),
      LockStatus.locked => const LockScreen(),
      LockStatus.unlocked => widget.child,
    };
    // Blank cover while the app is in the app switcher.
    return Stack(
      children: [
        body,
        if (_inactive && status == LockStatus.unlocked)
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
      ],
    );
  }
}
