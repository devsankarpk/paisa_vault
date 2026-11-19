import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shown before the Android SMS permission prompt. Google requires this plain explanation.
class SmsDisclosureScreen extends StatelessWidget {
  const SmsDisclosureScreen({
    super.key,
    required this.onAllow,
    required this.onSkip,
  });

  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: PvColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sms_outlined, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Read bank messages',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paisa Vault reads new bank and UPI SMS to record your spending automatically.\n\n'
                '• Messages are processed only on this phone.\n'
                '• They are never uploaded. The app has no server and no account.\n'
                '• Only new messages are used. Old messages are not read.\n'
                '• OTP and promotional messages are ignored.',
                style: TextStyle(fontSize: 16, height: 1.45),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAllow,
                  child: const Text('Continue'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('Not now, I will add transactions myself'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
