import '../models/transaction.dart';
import '../models/category.dart';
import '../models/month.dart';
import '../utils/jalali_helper.dart';
import '../utils/transaction_date.dart';
import 'api_client.dart';

void validateTransactionMonth(MoneyTransaction transaction) {
  TransactionCalendarDate date;
  try {
    date = TransactionCalendarDate.parse(transaction.date);
  } on FormatException {
    throw ApiException('تاریخ تراکنش نامعتبر است.');
  }
  final dateMonthKey = JalaliHelper.monthKeyFor(date.jalali);
  if (transaction.monthKey != dateMonthKey) {
    throw ApiException('ماه تراکنش با تاریخ انتخاب‌شده هماهنگ نیست.');
  }
}

class DataService {
  DataService._();
  static final DataService instance = DataService._();
  final _api = ApiClient.instance;

  // ── Categories ──────────────────────────────────────────────
  Future<List<MoneyCategory>> listCategories() async {
    final res = await _api.get('/api/categories');
    final list = apiJsonObjectList(res.data);
    return list.map(MoneyCategory.fromJson).toList();
  }

  Future<MoneyCategory> createCategory({
    required String id,
    required String label,
    String icon = '💰',
    String color = '#00e6ff',
    num? budget,
  }) async {
    final res = await _api.post('/api/categories', data: {
      'id': id,
      'label': label,
      'icon': icon,
      'color': color,
      'budget': budget,
    });
    return MoneyCategory.fromJson(apiJsonObject(res.data));
  }

  Future<MoneyCategory> updateCategory(
    String id, {
    String? label,
    String? icon,
    String? color,
    num? budget,
  }) async {
    final res = await _api.patch('/api/categories/$id', data: {
      'label': label,
      'icon': icon,
      'color': color,
      'budget': budget,
    });
    return MoneyCategory.fromJson(apiJsonObject(res.data));
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/api/categories/$id');
  }

  // ── Months ──────────────────────────────────────────────────
  Future<List<MonthInfo>> listMonths() async {
    final res = await _api.get('/api/months');
    final list = apiJsonObjectList(res.data);
    return list.map(MonthInfo.fromJson).toList();
  }

  Future<MonthInfo?> getMonth(String monthKey) async {
    final res = await _api.get('/api/months/$monthKey');
    if (res.data == null) return null;
    return MonthInfo.fromJson(apiJsonObject(res.data));
  }

  Future<MonthInfo> ensureMonth({
    required String monthKey,
    required String monthLabel,
    num startBalance = 0,
  }) async {
    final res = await _api.post('/api/months', data: {
      'month_key': monthKey,
      'month_label': monthLabel,
      'start_balance': startBalance,
    });
    return MonthInfo.fromJson(apiJsonObject(res.data));
  }

  Future<void> updateMonthStartBalance(
      String monthKey, num startBalance) async {
    await _api.patch('/api/months/$monthKey', data: {
      'start_balance': startBalance,
    });
  }

  // ── Transactions ────────────────────────────────────────────
  Future<List<MoneyTransaction>> listTransactions(String monthKey) async {
    final res =
        await _api.get('/api/transactions', query: {'month_key': monthKey});
    final list = apiJsonObjectList(res.data);
    return list.map(MoneyTransaction.fromJson).toList();
  }

  Future<List<MoneyTransaction>> listTransactionsMulti(
      List<String> monthKeys) async {
    final res = await _api.get('/api/transactions', query: {
      'month_keys': monthKeys.join(','),
    });
    final list = apiJsonObjectList(res.data);
    return list.map(MoneyTransaction.fromJson).toList();
  }

  Future<List<MoneyTransaction>> listRecurring() async {
    final res = await _api.get('/api/transactions/recurring');
    final list = apiJsonObjectList(res.data);
    return list.map(MoneyTransaction.fromJson).toList();
  }

  Future<MoneyTransaction> createTransaction(MoneyTransaction tx) async {
    if (!TransactionCalendarDate.isCanonical(tx.date)) {
      throw ApiException('تاریخ تراکنش باید با قالب YYYY-MM-DD ارسال شود.');
    }
    validateTransactionMonth(tx);
    final res = await _api.post('/api/transactions', data: tx.toJson());
    return MoneyTransaction.fromJson(apiJsonObject(res.data));
  }

  Future<MoneyTransaction> updateTransaction(
      String id, Map<String, dynamic> patch) async {
    if (patch.containsKey('date') &&
        (patch['date'] is! String ||
            !TransactionCalendarDate.isCanonical(patch['date'] as String))) {
      throw ApiException('تاریخ تراکنش باید با قالب YYYY-MM-DD ارسال شود.');
    }
    final res = await _api.patch('/api/transactions/$id', data: patch);
    return MoneyTransaction.fromJson(apiJsonObject(res.data));
  }

  Future<void> deleteTransaction(String id) async {
    await _api.delete('/api/transactions/$id');
  }

  Future<void> resetMonth(String monthKey) async {
    await _api.delete('/api/transactions', query: {'month_key': monthKey});
  }
}
