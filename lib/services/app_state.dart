import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../utils/jalali_helper.dart';
import '../utils/transaction_date.dart';
import '../utils/persian_numbers.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/month.dart';
import 'data_service.dart';
import 'goals_service.dart';

class RequestGeneration {
  int _value = 0;

  int next() => ++_value;
  void invalidate() => _value++;
  bool isCurrent(int generation) => generation == _value;
  int get current => _value;
}

typedef GoalLoader = Future<Goal?> Function(String monthKey);
typedef TransactionCreator = Future<MoneyTransaction> Function(
    MoneyTransaction transaction);
typedef TransactionDeleter = Future<void> Function(String id);
typedef MonthResetter = Future<void> Function(String monthKey);
typedef StartBalanceUpdater = Future<void> Function(
    String monthKey, num amount);
typedef MonthLoader = Future<MonthInfo?> Function(String monthKey);
typedef CategoryLoader = Future<List<MoneyCategory>> Function();

/// Holds the currently-viewed month and its data, shared across the
/// dashboard/transactions/summary tabs so they stay in sync and avoid
/// refetching on every tab switch.
class AppState extends ChangeNotifier {
  AppState._({
    GoalLoader? goalLoader,
    TransactionCreator? transactionCreator,
    TransactionDeleter? transactionDeleter,
    MonthResetter? monthResetter,
    StartBalanceUpdater? startBalanceUpdater,
    MonthLoader? monthLoader,
    CategoryLoader? categoryLoader,
    bool sessionActive = false,
  })  : _goalLoader = goalLoader ?? GoalsService.instance.getGoal,
        _transactionCreator =
            transactionCreator ?? DataService.instance.createTransaction,
        _transactionDeleter =
            transactionDeleter ?? DataService.instance.deleteTransaction,
        _monthResetter = monthResetter ?? DataService.instance.resetMonth,
        _startBalanceUpdater =
            startBalanceUpdater ?? DataService.instance.updateMonthStartBalance,
        _monthLoader = monthLoader ?? DataService.instance.getMonth,
        _categoryLoader = categoryLoader ?? DataService.instance.listCategories,
        _sessionActive = sessionActive;

  @visibleForTesting
  AppState.forTesting({
    GoalLoader? goalLoader,
    TransactionCreator? transactionCreator,
    TransactionDeleter? transactionDeleter,
    MonthResetter? monthResetter,
    StartBalanceUpdater? startBalanceUpdater,
    MonthLoader? monthLoader,
    CategoryLoader? categoryLoader,
  }) : this._(
          goalLoader: goalLoader,
          transactionCreator: transactionCreator,
          transactionDeleter: transactionDeleter,
          monthResetter: monthResetter,
          startBalanceUpdater: startBalanceUpdater,
          monthLoader: monthLoader,
          categoryLoader: categoryLoader,
          sessionActive: true,
        );

  static final AppState instance = AppState._();

  final GoalLoader _goalLoader;
  final TransactionCreator _transactionCreator;
  final TransactionDeleter _transactionDeleter;
  final MonthResetter _monthResetter;
  final StartBalanceUpdater _startBalanceUpdater;
  final MonthLoader _monthLoader;
  final CategoryLoader _categoryLoader;

  Jalali selectedMonth = Jalali.now();
  List<MoneyCategory> categories = [];
  List<MoneyTransaction> transactions = [];
  MonthInfo? monthInfo;
  Goal? goal;
  bool loading = false;
  final RequestGeneration _monthRequests = RequestGeneration();
  final RequestGeneration _sessionRequests = RequestGeneration();
  bool _sessionActive;
  int _sessionGeneration = 0;

  /// Clears every cached field. MUST be called on logout, on account
  /// deletion, and defensively on every fresh app entry — otherwise a
  /// different account logging in within the same running app session
  /// would briefly (or, for the `categories.isEmpty` case below, not so
  /// briefly) see the previous account's categories/transactions/month.
  int beginAuthenticationTransition() {
    _sessionGeneration = _sessionRequests.next();
    _sessionActive = false;
    _clearUserState();
    return _sessionGeneration;
  }

  bool activateSession(int generation) {
    if (!_sessionRequests.isCurrent(generation)) return false;
    _sessionActive = true;
    _clearUserState();
    return true;
  }

  void resetForAuthenticatedEntry() {
    _sessionRequests.invalidate();
    _sessionGeneration = _sessionRequests.current;
    _sessionActive = true;
    _clearUserState();
  }

  void reset() {
    _sessionRequests.invalidate();
    _sessionGeneration = _sessionRequests.current;
    _sessionActive = false;
    _clearUserState();
  }

  int get currentSessionGeneration => _sessionGeneration;

  bool isSessionTransitionCurrent(int generation) =>
      _sessionRequests.isCurrent(generation);

  bool isSessionGenerationCurrent(int generation) =>
      _sessionActive && _sessionRequests.isCurrent(generation);

  void _clearUserState() {
    _monthRequests.invalidate();
    selectedMonth = Jalali.now();
    categories = [];
    transactions = [];
    monthInfo = null;
    goal = null;
    loading = false;
    _previousMonthNet = null;
    notifyListeners();
  }

  String get monthKey => JalaliHelper.monthKeyFor(selectedMonth);
  String get monthLabel => JalaliHelper.monthLabelFor(selectedMonth);

  num get income =>
      transactions.where((t) => t.isIncome).fold(0, (a, t) => a + t.amount);
  num get expense =>
      transactions.where((t) => !t.isIncome).fold(0, (a, t) => a + t.amount);
  num get balance => (monthInfo?.startBalance ?? 0) + income - expense;

  bool get isCurrentMonthSelected =>
      monthKey == JalaliHelper.monthKeyFor(Jalali.now());

  /// Today's date, formatted for the dashboard header (e.g. "۱۲ مرداد").
  String get todayLabel =>
      JalaliHelper.formatShort(DateTime.now().toIso8601String());

  int get daysInSelectedMonth => selectedMonth.monthLength;

  /// How many days into the selected month we are. For a past month this
  /// is the whole month (it's over); for a future month, zero.
  int get daysElapsedInSelectedMonth {
    final todayKey = JalaliHelper.monthKeyFor(Jalali.now());
    if (monthKey == todayKey) return Jalali.now().day;
    // Compare year-month ordering via the key string ("YYYY-MM" sorts lexically).
    return monthKey.compareTo(todayKey) < 0 ? daysInSelectedMonth : 0;
  }

  /// Days remaining until the selected month ends (0 for past months).
  int get daysLeftInSelectedMonth {
    final left = daysInSelectedMonth - daysElapsedInSelectedMonth;
    return left < 0 ? 0 : left;
  }

  /// Average toman spent per elapsed day this month — the figure people
  /// actually use to gut-check "am I on pace".
  num get dailyAverageSpend {
    final days = daysElapsedInSelectedMonth;
    if (days <= 0) return 0;
    return expense / days;
  }

  String get dailyAverageSpendLabel =>
      PersianNumbers.formatAmount(dailyAverageSpend.round());

  /// Total of every category's monthly budget (categories without a budget
  /// don't count). Used as the denominator for the small "٪ از بودجه" ring
  /// on the balance card.
  num get totalCategoryBudget =>
      categories.fold<num>(0, (a, c) => a + (c.budget ?? 0));

  /// How much of the month's budget has been used, 0..1. Falls back to
  /// expense-vs-income when no category budgets are set, so the ring still
  /// shows something meaningful for a brand-new account.
  double get budgetUsageRatio {
    final budget = totalCategoryBudget;
    if (budget > 0) return (expense / budget).clamp(0.0, 1.0);
    // BUG FIX: the old fallback compared expense to this month's raw
    // *income*. That's wrong whenever someone hasn't logged fresh
    // income yet this month but still has a carried-over balance (very
    // common right after onboarding, or in any month where income
    // arrives later than expenses do) — income == 0 made this always
    // return 0%, regardless of how much was actually spent. The
    // correct implied "funds available this month" is the balance you
    // started the month with plus whatever income has come in since,
    // not income alone.
    final impliedMonthlyFunds = (monthInfo?.startBalance ?? 0) + income;
    if (impliedMonthlyFunds > 0) {
      return (expense / impliedMonthlyFunds).clamp(0.0, 1.0);
    }
    return 0;
  }

  /// Sum of today's expense transactions (used by the "امروز چقدر می‌تونی
  /// خرج کنی؟" card). Only meaningful while viewing the current month.
  num get spentToday {
    final now = DateTime.now();
    return transactions.where((t) => !t.isIncome).where((t) {
      final d = TransactionCalendarDate.parse(t.date);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold<num>(0, (a, t) => a + t.amount);
  }

  /// A simple, defensible "safe to spend today" figure: whatever's left
  /// of the month's balance, spread evenly across the days remaining.
  /// Not a real budgeting engine — just a sanity-check number so today
  /// doesn't quietly wreck the rest of the month.
  num get safeDailyAllowance {
    final days = daysLeftInSelectedMonth;
    if (days <= 0) return balance > 0 ? balance : 0;
    final allowance = balance / days;
    return allowance > 0 ? allowance : 0;
  }

  double get dailyAllowanceUsedRatio => safeDailyAllowance > 0
      ? (spentToday / safeDailyAllowance).clamp(0.0, 1.0)
      : 0;

  // ── Month-over-month comparison (for the "١٣٪ نسبت به ماه قبل" chip) ──
  num? _previousMonthNet;

  /// Net savings (income − expense) for the month immediately before the
  /// one currently selected, or null until it's been fetched.
  num? get previousMonthNet => _previousMonthNet;

  num get _thisMonthNet => income - expense;

  /// Percent change in net savings vs. the previous month. Null until the
  /// comparison data has loaded or if there's nothing meaningful to
  /// compare against (previous month had zero net activity).
  double? get monthOverMonthChangePercent {
    final prev = _previousMonthNet;
    if (prev == null || prev == 0) return null;
    return ((_thisMonthNet - prev) / prev.abs()) * 100;
  }

  Future<void> loadPreviousMonthComparison({
    Jalali? forMonth,
    int? requestGeneration,
  }) async {
    final targetMonth = forMonth ?? selectedMonth;
    final generation = requestGeneration ?? _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) return;
    try {
      final prevMonth = targetMonth.month == 1
          ? Jalali(targetMonth.year - 1, 12, 1)
          : Jalali(targetMonth.year, targetMonth.month - 1, 1);
      final prevKey = JalaliHelper.monthKeyFor(prevMonth);
      final prevTx = await DataService.instance.listTransactions(prevKey);
      final prevIncome =
          prevTx.where((t) => t.isIncome).fold<num>(0, (a, t) => a + t.amount);
      final prevExpense =
          prevTx.where((t) => !t.isIncome).fold<num>(0, (a, t) => a + t.amount);
      if (!isSessionGenerationCurrent(sessionGeneration) ||
          !_monthRequests.isCurrent(generation) ||
          monthKey != JalaliHelper.monthKeyFor(targetMonth)) {
        return;
      }
      _previousMonthNet = prevIncome - prevExpense;
    } catch (_) {
      if (!isSessionGenerationCurrent(sessionGeneration) ||
          !_monthRequests.isCurrent(generation)) {
        return;
      }
      _previousMonthNet = null;
    } finally {
      if (isSessionGenerationCurrent(sessionGeneration) &&
          _monthRequests.isCurrent(generation)) {
        notifyListeners();
      }
    }
  }

  Future<void> loadCategories() async {
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    final loadedCategories = await _categoryLoader();
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    categories = loadedCategories;
    notifyListeners();
  }

  Future<void> loadMonth() async {
    final targetMonth = selectedMonth;
    final targetKey = JalaliHelper.monthKeyFor(targetMonth);
    final targetLabel = JalaliHelper.monthLabelFor(targetMonth);
    final generation = _monthRequests.next();
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    loading = true;
    _previousMonthNet = null;
    notifyListeners();
    try {
      final loadedMonth = await DataService.instance.ensureMonth(
        monthKey: targetKey,
        monthLabel: targetLabel,
      );
      final loadedTransactions =
          await DataService.instance.listTransactions(targetKey);
      // Always refetch categories fresh (not "only if empty" — a stale,
      // non-empty list from a previous account would otherwise never
      // get replaced).
      final loadedCategories = await DataService.instance.listCategories();
      final loadedGoal = await GoalsService.instance.getGoal(targetKey);

      if (!_isRequestSnapshotCurrent(
          targetKey, generation, sessionGeneration)) {
        return;
      }
      monthInfo = loadedMonth;
      transactions = loadedTransactions;
      categories = loadedCategories;
      goal = loadedGoal;
    } catch (_) {
      if (!_isRequestSnapshotCurrent(
          targetKey, generation, sessionGeneration)) {
        return;
      }
      rethrow;
    } finally {
      if (_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
        loading = false;
        notifyListeners();
      }
    }
    // Fire-and-forget: doesn't block the main dashboard render.
    unawaited(loadPreviousMonthComparison(
      forMonth: targetMonth,
      requestGeneration: generation,
    ));
  }

  Future<void> goToMonth(Jalali month) async {
    selectedMonth = month;
    await loadMonth();
  }

  Future<void> nextMonth() async {
    final m = selectedMonth.month == 12
        ? Jalali(selectedMonth.year + 1, 1, 1)
        : Jalali(selectedMonth.year, selectedMonth.month + 1, 1);
    await goToMonth(m);
  }

  Future<void> prevMonth() async {
    final m = selectedMonth.month == 1
        ? Jalali(selectedMonth.year - 1, 12, 1)
        : Jalali(selectedMonth.year, selectedMonth.month - 1, 1);
    await goToMonth(m);
  }

  MoneyCategory? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> addTransaction(MoneyTransaction tx) async {
    final targetKey = monthKey;
    final generation = _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    final created = await _transactionCreator(tx);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    if (created.monthKey == targetKey) transactions.add(created);
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    final targetKey = monthKey;
    final generation = _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    await _transactionDeleter(id);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> resetCurrentMonth() async {
    final targetKey = monthKey;
    final generation = _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    await _monthResetter(targetKey);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    transactions = [];
    notifyListeners();
  }

  Future<void> refreshGoal() async {
    final targetKey = monthKey;
    final generation = _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    final loadedGoal = await _goalLoader(targetKey);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    goal = loadedGoal;
    notifyListeners();
  }

  Future<void> setStartBalance(num amount) async {
    final targetKey = monthKey;
    final generation = _monthRequests.current;
    final sessionGeneration = currentSessionGeneration;
    if (!isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    await _startBalanceUpdater(targetKey, amount);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    final loadedMonth = await _monthLoader(targetKey);
    if (!_isRequestSnapshotCurrent(targetKey, generation, sessionGeneration)) {
      return;
    }
    monthInfo = loadedMonth;
    notifyListeners();
  }

  bool _isRequestSnapshotCurrent(
          String targetKey, int generation, int sessionGeneration) =>
      isSessionGenerationCurrent(sessionGeneration) &&
      _monthRequests.isCurrent(generation) &&
      monthKey == targetKey;
}
