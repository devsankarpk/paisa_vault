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
    Future.microtask(() => ref.read(lockControllerProvider.notifier).load());
  }

  @override
  void dispose() {
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
      LockStatus.unlocked => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => ref.read(lockControllerProvider.notifier).touch(),
        child: widget.child,
      ),
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
