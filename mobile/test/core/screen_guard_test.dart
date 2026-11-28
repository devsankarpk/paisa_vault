import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/ui/screen_guard.dart';

void main() {
  testWidgets(
    'protection is on while a secure page is open, off after the last closes',
    (t) async {
      final guard = FakeScreenGuard();
      Widget app(bool a, bool b) => ProviderScope(
        overrides: [screenGuardProvider.overrideWithValue(guard)],
        child: MaterialApp(
          home: Column(
            children: [
              if (a) const SecureScreen(child: Text('a')),
              if (b) const SecureScreen(child: Text('b')),
              const Text('plain'),
            ],
          ),
        ),
      );

      await t.pumpWidget(app(false, false));
      expect(guard.changes, isEmpty);
      await t.pumpWidget(app(true, false));
      expect(guard.changes, [true]);
      await t.pumpWidget(
        app(true, true),
      ); // a second page: still on, no extra call
      expect(guard.changes, [true]);
      await t.pumpWidget(app(false, true)); // one closed: still on
      expect(guard.isOn, isTrue);
      expect(guard.changes, [true]);
      await t.pumpWidget(app(false, false));
      expect(guard.changes, [true, false]);
    },
  );
}
