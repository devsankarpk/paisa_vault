import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Newer Android versions draw the app behind the navigation bar, which hides the last row of
/// every list. This keeps the whole app above it. iPhone already handles its home indicator.
class SystemBarPadding extends StatelessWidget {
  const SystemBarPadding({super.key, required this.child, this.force});
  final Widget child;

  /// For tests: apply the padding whatever the platform.
  final bool? force;

  @override
  Widget build(BuildContext context) {
    final apply = force ?? defaultTargetPlatform == TargetPlatform.android;
    if (!apply) return child;
    return ColoredBox(
      color: PvColors.background,
      child: SafeArea(top: false, left: false, right: false, child: child),
    );
  }
}
