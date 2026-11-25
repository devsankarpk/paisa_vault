import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transactions/providers.dart';

/// When the app last saved a message that came from the phone. Null if none yet.
final lastBankMessageProvider = FutureProvider<DateTime?>((ref) async {
  final repo = await ref.watch(rawMessageRepositoryProvider.future);
  return repo.lastSavedAt();
});

/// Without a bank SMS for this long, the Shortcuts automation may have stopped.
const shortcutStaleAfter = Duration(days: 7);

enum ShortcutHealth { ok, neverReceived, stale }

/// iPhone gives no signal when an automation fails to run, so the only evidence is whether
/// messages keep arriving. A quiet account looks the same, so this only prompts a check.
ShortcutHealth shortcutHealth(DateTime? lastReceived, DateTime now) {
  if (lastReceived == null) return ShortcutHealth.neverReceived;
  return now.difference(lastReceived) > shortcutStaleAfter
      ? ShortcutHealth.stale
      : ShortcutHealth.ok;
}

/// Whole days since [lastReceived].
int daysSince(DateTime lastReceived, DateTime now) =>
    now.difference(lastReceived).inDays;
