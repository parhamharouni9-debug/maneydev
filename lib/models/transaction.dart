import 'json_parsing.dart';
import '../utils/transaction_date.dart';

class MoneyTransaction {
  final String id;
  final String monthKey;
  final String type; // 'income' | 'expense'
  final num amount;
  final String? category;
  final String? source;
  final String? note;
  final String date; // Canonical YYYY-MM-DD; legacy ISO timestamps read-only.
  final bool recurring;
  final String? recurringSource;

  MoneyTransaction({
    required this.id,
    required this.monthKey,
    required this.type,
    required this.amount,
    this.category,
    this.source,
    this.note,
    required this.date,
    this.recurring = false,
    this.recurringSource,
  });

  bool get isIncome => type == 'income';

  factory MoneyTransaction.fromJson(Map<String, dynamic> j) => MoneyTransaction(
        id: requiredText(j, 'id'),
        monthKey: requiredText(j, 'month_key'),
        type: oneOfText(j, 'type', {'income', 'expense'}),
        amount: requiredNumber(j, 'amount'),
        category: optionalText(j, 'category'),
        source: optionalText(j, 'source'),
        note: optionalText(j, 'note'),
        date: _transactionDateText(j),
        recurring: booleanValue(j, 'recurring'),
        recurringSource: optionalText(j, 'recurring_source'),
      );

  Map<String, dynamic> toJson() => {
        'month_key': monthKey,
        'type': type,
        'amount': amount,
        'category': category,
        'source': source,
        'note': note,
        'date': date,
        'recurring': recurring,
        'recurring_source': recurringSource,
      };

  MoneyTransaction copyWith({
    String? id,
    String? monthKey,
    String? type,
    num? amount,
    String? category,
    String? source,
    String? note,
    String? date,
    bool? recurring,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      monthKey: monthKey ?? this.monthKey,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      source: source ?? this.source,
      note: note ?? this.note,
      date: date ?? this.date,
      recurring: recurring ?? this.recurring,
      recurringSource: recurringSource,
    );
  }
}

String _transactionDateText(Map<String, dynamic> json) {
  final value = requiredText(json, 'date');
  TransactionCalendarDate.parse(value);
  return value;
}
