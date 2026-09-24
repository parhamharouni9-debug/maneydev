import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../utils/persian_numbers.dart';
import '../../models/transaction.dart';
import '../settings/settings_screen.dart';
import '../goals/goals_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../widgets/animated_goal_bar.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../utils/jalali_helper.dart';
import '../../utils/transaction_date.dart';
import '../../utils/month_comparison_presentation.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../widgets/category_icon.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _app = AppState.instance;
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onChange);
    if (_app.transactions.isEmpty) _app.loadMonth();
  }

  void _onChange() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _app.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                title: const Text('پول من'),
                actions: [
                  const ThemeToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              body: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.82, -0.92),
                    radius: 1.15,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.035),
                      AppColors.bg,
                    ],
                  ),
                ),
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardBg,
                  onRefresh: _app.loadMonth,
                  child: _app.loading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          children: [
                            _monthNav(),
                            const SizedBox(height: 10),
                            _balanceCard(),
                            const SizedBox(height: 10),
                            _incomeExpenseRow(),
                            const SizedBox(height: 10),
                            _dailyAllowanceCard(),
                            if (_app.transactions.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _sectionHeader('آخرین تراکنش‌ها',
                                  onSeeAll: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const TransactionsScreen()),
                                      )),
                              const SizedBox(height: 10),
                              ..._recentTransactions().map(_transactionRow),
                            ],
                            if (_app.goal != null) ...[
                              const SizedBox(height: 14),
                              _sectionHeader('هدف این ماه',
                                  onSeeAll: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const GoalsScreen()),
                                      )),
                              const SizedBox(height: 8),
                              _goalRow(),
                            ],
                          ],
                        ),
                ),
              ),
            ));
  }

  Widget _monthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          onPressed: _app.nextMonth, // RTL: visually right, moves forward
        ),
        Row(children: [
          Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(_app.monthLabel,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: AppColors.muted),
          onPressed: _app.prevMonth,
        ),
      ],
    );
  }

  // ── Balance card: number + budget ring + month-over-month chip ───
  Widget _balanceCard() {
    final positive = _app.balance >= 0;
    final comparison = presentNetSavingsComparison(
      currentNet: _app.income - _app.expense,
      previousNet: _app.previousMonthNet,
      formatPercent: PersianNumbers.toFa,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.cardBgAlt.withValues(alpha: 0.42),
            AppColors.cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('موجودی این ماه',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _balanceHidden = !_balanceHidden),
                        child: Icon(
                          _balanceHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      _balanceHidden
                          ? '••••••••'
                          : PersianNumbers.formatAmount(_app.balance),
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: positive ? AppColors.text : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('تومان',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              _MiniBudgetRing(ratio: _app.budgetUsageRatio),
            ],
          ),
          if (comparison != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: (comparison.neutral
                        ? AppColors.muted
                        : comparison.beneficial
                            ? AppColors.success
                            : AppColors.secondary)
                    .withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (comparison.neutral
                          ? AppColors.muted
                          : comparison.beneficial
                              ? AppColors.success
                              : AppColors.secondary)
                      .withValues(alpha: 0.16),
                ),
              ),
              child: Row(children: [
                Icon(
                  comparison.neutral
                      ? Icons.horizontal_rule_rounded
                      : comparison.increased
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                  size: 17,
                  color: comparison.neutral
                      ? AppColors.muted
                      : comparison.beneficial
                          ? AppColors.success
                          : AppColors.secondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    comparison.text,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: comparison.neutral
                          ? AppColors.muted
                          : comparison.beneficial
                              ? AppColors.success
                              : AppColors.secondary,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _incomeExpenseRow() {
    final remaining = _app.totalCategoryBudget > 0
        ? (_app.totalCategoryBudget - _app.expense).clamp(0, double.infinity)
        : _app.balance.clamp(0, double.infinity);
    return Column(children: [
      Row(children: [
        Expanded(
            child: _statCard('درآمد', PersianNumbers.formatAmount(_app.income),
                AppColors.success, Icons.south_west_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('هزینه', PersianNumbers.formatAmount(_app.expense),
                AppColors.secondary, Icons.north_east_rounded)),
      ]),
      const SizedBox(height: 10),
      _compactRemainingBudget(remaining),
    ]);
  }

  Widget _compactRemainingBudget(num remaining) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primary.withValues(alpha: 0.028),
              AppColors.cardBg,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.11)),
        ),
        child: Row(children: [
          Icon(Icons.account_balance_wallet_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Text('بودجه باقی‌مانده',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${PersianNumbers.formatAmount(remaining)} تومان',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );

  Widget _statCard(String label, String valueText, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color.withValues(alpha: 0.032), AppColors.cardBg],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.18))),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(valueText,
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text('تومان',
              style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
        ],
      ),
    );
  }

  // ── "امروز چقدر می‌تونی خرج کنی؟" ─────────────────────────────────
  Widget _dailyAllowanceCard() {
    final allowance = _app.safeDailyAllowance;
    final spent = _app.spentToday;
    final ratio = _app.dailyAllowanceUsedRatio;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => _showAllowanceInfo(context, allowance),
              child: Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColors.muted),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text('امروز چقدر می‌تونی خرج کنی؟',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary, size: 18),
            ),
          ]),
          const SizedBox(height: 10),
          Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                    PersianNumbers.formatAmount(
                        (allowance - spent).clamp(0, allowance)),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                const SizedBox(width: 6),
                Text('تومان',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
          const SizedBox(height: 10),
          AnimatedGoalBar(value: ratio, color: AppColors.primary, height: 6),
          const SizedBox(height: 6),
          Text('از ${PersianNumbers.formatAmount(allowance.round())} تومان',
              style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  // Explains the daily-allowance number using the *real* formula from
  // AppState.safeDailyAllowance — balance ÷ days left in the month.
  // Nothing invented here; if the formula in app_state.dart changes,
  // this copy needs to be updated to match.
  void _showAllowanceInfo(BuildContext context, num allowance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('این عدد چطور حساب می‌شه؟',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Text(
                  'موجودی فعلی این ماهت رو روی تعداد روزهایی که تا پایان ماه مونده تقسیم می‌کنیم. '
                  'یعنی اگه هر روز همین مقدار خرج کنی، دقیقاً تا آخر ماه موجودیت به صفر می‌رسه — نه کمتر، نه بیشتر.',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 13, height: 1.9),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.cardBgAlt,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formulaLine('موجودی این ماه',
                          PersianNumbers.formatAmount(_app.balance)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      _formulaLine('روز باقی‌مونده تا پایان ماه',
                          PersianNumbers.toFa(_app.daysLeftInSelectedMonth)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      _formulaLine('= امروز می‌تونی خرج کنی',
                          '${PersianNumbers.formatAmount(allowance.round())} تومان',
                          highlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'این فقط یه راهنماست، نه یه بودجه‌ی سخت‌گیرانه — هر روز که کمتر خرج کنی، سهم روزهای بعدت بیشتر می‌شه.',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 11.5, height: 1.7),
                ),
              ],
            ),
          )),
    );
  }

  Widget _formulaLine(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
        Text(value,
            style: TextStyle(
              color: highlight ? AppColors.primary : AppColors.text,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: highlight ? 14 : 13,
            )),
      ],
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text('همه',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Goal preview row ───────────────────────────────────────────────
  Widget _goalRow() {
    final goal = _app.goal!;
    final netSaved = _app.balance;
    final ratio = goal.targetAmount > 0
        ? (netSaved / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final reached = goal.targetAmount > 0 && netSaved >= goal.targetAmount;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.track_changes_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          goal.label?.isNotEmpty == true
                              ? goal.label!
                              : 'هدف مالی این ماه',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        reached
                            ? '۱۰۰٪'
                            : '${PersianNumbers.toFa((ratio * 100).round())}٪',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${PersianNumbers.formatAmount(netSaved.clamp(0, double.infinity))} از ${PersianNumbers.formatAmount(goal.targetAmount)} تومان',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                  AnimatedGoalBar(
                      value: ratio, color: AppColors.primary, height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent transactions preview ───────────────────────────────────
  List<MoneyTransaction> _recentTransactions() {
    final list = [..._app.transactions]..sort((a, b) {
        final byDate = compareTransactionDates(b.date, a.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return list.take(3).toList();
  }

  Widget _transactionRow(MoneyTransaction tx) {
    final cat = _app.categoryById(tx.category);
    final color = tx.isIncome ? AppColors.success : AppColors.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: tx.isIncome && cat == null
              ? Icon(Icons.payments_rounded, color: color, size: 19)
              : CategoryIcon(value: cat?.icon, color: color, size: 19),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(JalaliHelper.formatShort(tx.date),
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ),
        Text(
          '${tx.isIncome ? '+' : '−'}${PersianNumbers.formatAmount(tx.amount)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ]),
    );
  }
}

/// The small circular "٪ از بودجه" badge on the balance card.
class _MiniBudgetRing extends StatelessWidget {
  final double ratio;
  const _MiniBudgetRing({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final over = ratio >= 1;
    final color = over ? AppColors.secondary : AppColors.primary;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              color: AppColors.cardBgAlt,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: value == 0 ? 0.001 : value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${PersianNumbers.toFa((ratio * 100).round())}٪',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              Text('از بودجه',
                  style: TextStyle(fontSize: 7.5, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
