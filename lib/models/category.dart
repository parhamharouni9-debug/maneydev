import 'json_parsing.dart';

class MoneyCategory {
  final String id;
  final String label;
  final String icon;
  final String color;
  final num? budget;
  final bool isDefault;

  MoneyCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.budget,
    this.isDefault = false,
  });

  factory MoneyCategory.fromJson(Map<String, dynamic> j) => MoneyCategory(
        id: requiredText(j, 'id'),
        label: requiredText(j, 'label'),
        icon: optionalText(j, 'icon') ?? '💰',
        color: optionalText(j, 'color') ?? '#00e6ff',
        budget: optionalNumber(j, 'budget'),
        isDefault: booleanValue(j, 'is_default'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': icon,
        'color': color,
        'budget': budget,
      };
}
