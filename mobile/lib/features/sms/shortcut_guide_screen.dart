import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import 'shortcut_health.dart';

/// iPhone only: how to set up the Shortcuts automation that sends each bank SMS to the app.
class ShortcutGuideScreen extends StatelessWidget {
  const ShortcutGuideScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
  });

  final VoidCallback onDone;
  final VoidCallback onSkip;

  static const steps = [
    'Open Shortcuts, then Automation, then New, then Message',
    'Set "Message contains" to one keyword: debited, credited, spent, Rs or INR. Repeat per keyword.',
    'Choose "Run Immediately"',
    'Add the action "Log Bank Message" (Paisa Vault) with the message as input',
    'Done. New bank SMS are saved and processed when you next open the app.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'iPhone Shortcut setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            _Card(
              color: const Color(0xFFE8EEFF),
              child: const Text(
                'iPhone does not let apps read SMS. A one-time Shortcuts automation sends each new bank SMS to Paisa Vault. '
                'Messages stay on this phone.',
                style: TextStyle(
                  color: Color(0xFF3F57B5),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            for (var i = 0; i < steps.length; i++)
              _Card(
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: PvColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(fontSize: 15, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            _Card(
              color: const Color(0xFFFDF6E3),
              child: const Text(
                'iOS may show a small "Shortcut ran" banner each time. This is normal.',
                style: TextStyle(
                  color: Color(0xFFA06A10),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const _TestCard(),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onDone,
              child: const Text('I have set it up'),
            ),
            TextButton(onPressed: onSkip, child: const Text('Not now')),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

/// Step 6: proves the automation works. Ask someone to text you a message with the word
/// "debited" (for example "test debited"). It turns green when the app receives one.
class _TestCard extends ConsumerStatefulWidget {
  const _TestCard();

  @override
  ConsumerState<_TestCard> createState() => _TestCardState();
}

class _TestCardState extends ConsumerState<_TestCard> {
  late final DateTime _openedAt = ref.read(clockProvider).now();

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(lastBankMessageProvider).asData?.value;
    final got = last != null && !last.isBefore(_openedAt);
    return _Card(
      color: got ? const Color(0xFFE6F6EC) : Colors.white,
      child: Row(
        children: [
          Icon(
            got ? Icons.check_circle : Icons.hourglass_empty,
            color: got ? const Color(0xFF1E8E4E) : PvColors.muted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              got
                  ? 'Test message received. Your automation works.'
                  : 'Test it: ask someone to text you "test debited", then come back here. '
                        'This turns green when the message arrives.',
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the setup guide on top of the current screen (from the banner or Settings).
Future<void> openShortcutGuide(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => ShortcutGuideScreen(
          onDone: () => Navigator.of(c).pop(),
          onSkip: () => Navigator.of(c).pop(),
        ),
      ),
    );
