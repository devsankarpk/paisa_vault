import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'raw_message_repository.dart';
import 'shortcut_guide_screen.dart';
import 'sms_disclosure_screen.dart';

final smsIngestProvider = FutureProvider<SmsIngest>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return SmsIngest(
    ref.watch(smsSourceProvider),
    RawMessageRepository(db, ref.watch(clockProvider)),
  );
});

const _disclosureSeenKey = 'pv_sms_disclosure_seen';
const _guideSeenKey = 'pv_shortcut_guide_seen';

/// Shown only while unlocked. Asks for SMS access once (after the disclosure), then saves staged
/// messages when the app opens, comes back to the foreground, or a message arrives.
class SmsRunner extends ConsumerStatefulWidget {
  const SmsRunner({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SmsRunner> createState() => _SmsRunnerState();
}

class _SmsRunnerState extends ConsumerState<SmsRunner>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sub;
  bool? _needsDisclosure;
  bool _needsGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = ref.read(smsSourceProvider).arrivals.listen((_) => _drain());
    _init();
  }

  Future<void> _init() async {
    final source = ref.read(smsSourceProvider);
    final store = ref.read(secretStoreProvider);
    final seen = await store.read(_disclosureSeenKey) == 'true';
    final guideSeen = await store.read(_guideSeenKey) == 'true';
    final granted = await source.hasPermission;
    if (!mounted) return;
    setState(() {
      _needsDisclosure = !granted && !seen;
      _needsGuide = ref.read(needsShortcutGuideProvider) && !guideSeen;
    });
    if (granted) await _drain();
  }

  Future<void> _drain() async {
    try {
      final ingest = await ref.read(smsIngestProvider.future);
      final saved = await ingest.drain();
      // Counts only. Never print message text.
      if (saved > 0) debugPrint('PV_INGEST saved=$saved');
    } catch (e) {
      // Left staged; the next drain retries. Only the error type is logged, never its text.
      debugPrint('PV_INGEST failed ${e.runtimeType}');
    }
  }

  Future<void> _allow() async {
    await ref.read(secretStoreProvider).write(_disclosureSeenKey, 'true');
    final granted = await ref.read(smsSourceProvider).requestPermission();
    if (!mounted) return;
    setState(() => _needsDisclosure = false);
    if (granted) await _drain();
  }

  Future<void> _skip() async {
    await ref.read(secretStoreProvider).write(_disclosureSeenKey, 'true');
    if (mounted) setState(() => _needsDisclosure = false);
  }

  Future<void> _guideDone() async {
    await ref.read(secretStoreProvider).write(_guideSeenKey, 'true');
    if (mounted) setState(() => _needsGuide = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _drain();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_needsDisclosure) {
      null => const Scaffold(body: SizedBox.shrink()),
      true => SmsDisclosureScreen(onAllow: _allow, onSkip: _skip),
      false when _needsGuide => ShortcutGuideScreen(
        onDone: _guideDone,
        onSkip: _guideDone,
      ),
      false => widget.child,
    };
  }
}
