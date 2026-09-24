import 'json_parsing.dart';

class MonthInfo {
  final String id;
  final String monthKey; // e.g. "1403-05"
  final String monthLabel; // e.g. "مرداد ۱۴۰۳"
  final num startBalance;

  MonthInfo({
    required this.id,
    required this.monthKey,
    required this.monthLabel,
    required this.startBalance,
  });

  factory MonthInfo.fromJson(Map<String, dynamic> j) => MonthInfo(
        id: optionalText(j, 'id') ?? '',
        monthKey: requiredText(j, 'month_key'),
        monthLabel: requiredText(j, 'month_label'),
        startBalance: optionalNumber(j, 'start_balance') ?? 0,
      );
}

class Goal {
  final String id;
  final String monthKey;
  final num targetAmount;
  final String? label;

  Goal({
    required this.id,
    required this.monthKey,
    required this.targetAmount,
    this.label,
  });

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: optionalText(j, 'id') ?? '',
        monthKey: requiredText(j, 'month_key'),
        targetAmount: requiredNumber(j, 'target_amount'),
        label: optionalText(j, 'label'),
      );
}
