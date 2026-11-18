import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Number pad with PIN dots. Calls [onComplete] when [length] digits are entered.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.length,
    required this.onComplete,
    this.bottomLeft,
    this.enabled = true,
  });

  final int length;
  final Future<void> Function(String pin) onComplete;

  /// Optional widget in the empty bottom-left cell, such as "Use Face ID".
  final Widget? bottomLeft;
  final bool enabled;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _entered = '';
  bool _busy = false;

  void clear() => setState(() => _entered = '');

  Future<void> _tap(String d) async {
    if (!widget.enabled || _busy || _entered.length >= widget.length) return;
    setState(() => _entered += d);
    if (_entered.length == widget.length) {
      _busy = true;
      final pin = _entered;
      await widget.onComplete(pin);
      if (mounted) {
        setState(() {
          _entered = '';
          _busy = false;
        });
      }
    }
  }

  void _back() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label) => _Key(label: label, onTap: () => _tap(label));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Container(
                key: ValueKey('pin-dot-$i'),
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _entered.length
                      ? PvColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: i < _entered.length
                        ? PvColors.primary
                        : PvColors.dotBorder,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              height: 64,
              child: Center(child: widget.bottomLeft),
            ),
            key('0'),
            _Key(
              label: '',
              icon: Icons.backspace_outlined,
              semantics: 'Delete',
              onTap: _back,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.icon,
    this.semantics,
  });
  final String label;
  final IconData? icon;
  final String? semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Semantics(
        button: true,
        label: semantics ?? label,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          elevation: 1,
          shadowColor: PvColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(40),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onTap,
            child: SizedBox(
              width: 84,
              height: 64,
              child: Center(
                child: icon != null
                    ? Icon(icon, color: PvColors.ink)
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
