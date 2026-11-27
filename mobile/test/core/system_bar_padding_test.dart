import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_vault/core/ui/system_bar_padding.dart';

void main() {
  Future<double> bottomOf(WidgetTester t, {required bool force}) async {
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 48),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SystemBarPadding(
            force: force,
            child: const SizedBox.expand(key: Key('app')),
          ),
        ),
      ),
    );
    return t.getBottomLeft(find.byKey(const Key('app'))).dy;
  }

  testWidgets('keeps the app above the navigation bar when applied', (t) async {
    final plain = await bottomOf(t, force: false);
    expect(await bottomOf(t, force: true), plain - 48);
  });

  testWidgets('leaves the layout alone when not applied', (t) async {
    expect(await bottomOf(t, force: false), 600); // the whole test screen
  });
}
