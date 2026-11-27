import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../budgets/budgets_screen.dart';
import '../transactions/format.dart';
import '../transactions/providers.dart';
import 'month_summary.dart';

const _names = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _palette = [
  Color(0xFFFBBF24),
  Color(0xFF6B8DFD),
  Color(0xFF2E3A59),
  Color(0xFF5BD0F4),
  Color(0xFFA99BF0),
  Color(0xFFF08A8A),
  Color(0xFF7CCB9B),
];

/// Earning, spend and savings for a month, with spending split by category.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final thisMonth = DateTime(now.year, now.month);
    final month = _month ?? thisMonth;
    final all = ref.watch(transactionsProvider).asData?.value ?? const [];
    final s = summariseMonth(all, month);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Earlier month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _month = DateTime(month.year, month.month - 1),
                ),
              ),
              Text(
                '${_names[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'Later month',
                icon: const Icon(Icons.chevron_right),
                onPressed: month.isBefore(thisMonth)
                    ? () => setState(
                        () => _month = DateTime(month.year, month.month + 1),
                      )
                    : null,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: s.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Nothing recorded this month.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: PvColors.muted),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _Donut(s),
                          child: Center(
                            child: Text(
                              'Spend',
                              style: const TextStyle(color: PvColors.muted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Figure('Earning', s.earningPaise, PvColors.primary),
                          _Figure(
                            'Spend',
                            s.spendPaise,
                            const Color(0xFFB7791F),
                          ),
                          _Figure(
                            'Savings',
                            s.savingsPaise,
                            s.savingsPaise < 0 ? PvColors.error : PvColors.ink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < s.byCategory.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _palette[i % _palette.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s.byCategory[i].name)),
                              Text(
                                '₹${formatRupees(s.byCategory[i].paise)}  ${s.percentOf(s.byCategory[i])}%',
                                style: const TextStyle(color: PvColors.muted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
            ),
            child: const Text('Budgets'),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.paise, this.color);
  final String label;
  final int paise;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: PvColors.muted)),
      const SizedBox(height: 4),
      Text(
        '${paise < 0 ? '-' : ''}₹${formatRupees(paise.abs())}',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _Donut extends CustomPainter {
  _Donut(this.s);
  final MonthSummary s;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    var start = -math.pi / 2;
    for (var i = 0; i < s.byCategory.length; i++) {
      final sweep = 2 * math.pi * s.byCategory[i].paise / s.spendPaise;
      paint.color = _palette[i % _palette.length];
      canvas.drawArc(rect, start, math.max(sweep - 0.02, 0.01), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => old.s != s;
}
