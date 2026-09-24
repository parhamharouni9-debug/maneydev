import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../utils/persian_numbers.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/category_icon.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _app = AppState.instance;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onChange);
  }

  void _onChange() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _app.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, num>{};
    for (final t in _app.transactions.where((t) => !t.isIncome)) {
      final key = t.category ?? 'بدون دسته';
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
    final total = byCategory.values.fold<num>(0, (a, b) => a + b);
    final breakdown = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(title: Text('گزارش‌ها — ${_app.monthLabel}')),
              body: total == 0
                  ? const EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'هنوز خرجی برای نمایش نیست',
                      subtitle:
                          'وقتی چندتا خرج ثبت کنی، نموداری از دسته‌بندی‌هات اینجا نشون داده می‌شه',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.035),
                                AppColors.cardBg,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.14)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.055),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('مجموع خرج این ماه',
                                    style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.5)),
                                Text(
                                    '${PersianNumbers.formatAmount(total)} تومان',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 190,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    swapAnimationDuration:
                                        const Duration(milliseconds: 650),
                                    swapAnimationCurve: Curves.easeOutCubic,
                                    PieChartData(
                                      startDegreeOffset: -90,
                                      sectionsSpace:
                                          breakdown.length > 1 ? 3 : 0,
                                      centerSpaceRadius: 52,
                                      sections: breakdown.map((e) {
                                        final cat = _app.categoryById(e.key);
                                        final color =
                                            AppTheme.categoryColor(cat?.color);
                                        return PieChartSectionData(
                                          value: e.value.toDouble(),
                                          color: color,
                                          radius: 30,
                                          showTitle: false,
                                          borderSide: BorderSide(
                                            color:
                                                color.withValues(alpha: 0.28),
                                            width: 2,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('کل هزینه',
                                          style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11.5)),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          PersianNumbers.formatAmount(total),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Text('تومان',
                                          style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 9.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        Text('تفکیک هزینه‌ها',
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ...breakdown.map((e) {
                          final cat = _app.categoryById(e.key);
                          final color = AppTheme.categoryColor(cat?.color);
                          final share = total > 0 ? e.value / total : 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color.withValues(alpha: 0.028),
                                AppColors.cardBg,
                              ]),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.13)),
                            ),
                            child: Column(children: [
                              Row(children: [
                                Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(13)),
                                    alignment: Alignment.center,
                                    child: CategoryIcon(
                                        value: cat?.icon,
                                        color: color,
                                        size: 20)),
                                const SizedBox(width: 11),
                                Expanded(
                                    child: Text(cat?.label ?? e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '${PersianNumbers.formatAmount(e.value)} تومان',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5)),
                                    Text(
                                        '${PersianNumbers.toFa((share * 100).round())}٪ از هزینه‌ها',
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ]),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: share.toDouble(),
                                  minHeight: 5,
                                  color: color,
                                  backgroundColor:
                                      color.withValues(alpha: 0.10),
                                ),
                              ),
                            ]),
                          );
                        }),
                      ],
                    ),
            ));
  }
}
