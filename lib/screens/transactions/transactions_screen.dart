import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/transaction.dart';
import '../../utils/persian_numbers.dart';
import '../../utils/jalali_helper.dart';
import '../../utils/transaction_date.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../widgets/empty_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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

  Future<void> _confirmDelete(MoneyTransaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('حذف تراکنش؟'),
        content: const Text('این عملیات قابل بازگشت نیست.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _app.removeTransaction(tx.id);
    }
  }

  /// Buckets the (already date-descending sorted) list into
  /// "امروز" / "دیروز" / a Jalali date label for anything older —
  /// preserving chronological order within and across groups.
  List<MapEntry<String, List<MoneyTransaction>>> _grouped(
      List<MoneyTransaction> sorted) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<MoneyTransaction>>{};
    final order = <String>[];

    for (final tx in sorted) {
      final d = TransactionCalendarDate.parse(tx.date);
      String label;
      final isToday =
          d.year == today.year && d.month == today.month && d.day == today.day;
      final isYesterday = d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
      if (isToday) {
        label = 'امروز';
      } else if (isYesterday) {
        label = 'دیروز';
      } else {
        label = JalaliHelper.formatShort(tx.date);
      }
      if (!groups.containsKey(label)) {
        groups[label] = [];
        order.add(label);
      }
      groups[label]!.add(tx);
    }
    return order.map((k) => MapEntry(k, groups[k]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = [..._app.transactions]..sort((a, b) {
        final byDate = compareTransactionDates(b.date, a.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    final groups = _grouped(list);

    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(title: Text('تراکنش‌های ${_app.monthLabel}')),
              body: list.isEmpty
                  ? const EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: groups.length,
                      itemBuilder: (context, groupIndex) {
                        final entry = groups[groupIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  top: groupIndex == 0 ? 0 : 18,
                                  bottom: 10,
                                  right: 4),
                              child: Text(entry.key,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                            ...entry.value.map((tx) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _transactionTile(tx),
                                )),
                          ],
                        );
                      },
                    ),
            ));
  }

  Widget _transactionTile(MoneyTransaction tx) {
    final cat = _app.categoryById(tx.category);
    final color = tx.isIncome ? AppColors.success : AppColors.secondary;
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.secondary),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(tx);
        return false; // we handle removal via state; avoid double list mutation
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: tx.isIncome && cat == null
                ? Icon(Icons.payments_rounded, color: color, size: 20)
                : CategoryIcon(value: cat?.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.isIncome
                      ? (tx.source ?? 'درآمد')
                      : (cat?.label ?? 'بدون دسته'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(tx.note!,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        )),
                  ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '−'}${PersianNumbers.formatAmount(tx.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}
