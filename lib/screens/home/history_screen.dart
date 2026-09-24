import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../models/month.dart';
import '../../utils/persian_numbers.dart';
import '../../utils/jalali_helper.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../widgets/empty_state.dart';
import '../../utils/friendly_error.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MonthInfo> _months = [];
  Map<String, num> _monthTotals = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final months = await DataService.instance.listMonths();
      final keys = months.map((m) => m.monthKey).toList();
      final allTx = await DataService.instance.listTransactionsMulti(keys);
      final totals = <String, num>{};
      for (final t in allTx) {
        final signed = t.isIncome ? t.amount : -t.amount;
        totals[t.monthKey] = (totals[t.monthKey] ?? 0) + signed;
      }
      if (!mounted) return;
      setState(() {
        _months = months;
        _monthTotals = totals;
      });
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(title: const Text('تاریخچه ماه‌ها')),
              body: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.cyan))
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _load)
                      : _months.isEmpty
                          ? const EmptyState(
                              icon: Icons.calendar_month_rounded,
                              title: 'هنوز ماهی ثبت نشده',
                              subtitle:
                                  'وقتی چند ماه رو تموم کنی، تاریخچه‌ی موجودیت اینجا جمع می‌شه',
                            )
                          : RefreshIndicator(
                              color: AppColors.cyan,
                              backgroundColor: AppColors.cardBg,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _months.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final m = _months[i];
                                  final net = m.startBalance +
                                      (_monthTotals[m.monthKey] ?? 0);
                                  final positive = net >= 0;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await AppState.instance.goToMonth(
                                          JalaliHelper.parseMonthKey(
                                              m.monthKey));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'نمایش ${m.monthLabel} در تب خانه')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBg,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(children: [
                                        Expanded(
                                          child: Text(m.monthLabel,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                        Text(
                                          '${PersianNumbers.formatAmount(net)} تومان',
                                          style: TextStyle(
                                            color: positive
                                                ? AppColors.cyan
                                                : AppColors.magenta,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ),
            ));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
          ],
        ),
      );
}
