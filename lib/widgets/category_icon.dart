import 'package:flutter/material.dart';

/// Stable vector-icon vocabulary for categories. Existing backend values are
/// kept untouched; legacy emoji and common string aliases resolve here.
class CategoryIconData {
  final String key;
  final String label;
  final IconData icon;
  final List<String> aliases;

  const CategoryIconData(this.key, this.label, this.icon,
      [this.aliases = const []]);
}

const categoryIconChoices = <CategoryIconData>[
  CategoryIconData('food', 'خوراک', Icons.lunch_dining_rounded, ['🍕', '🍔']),
  CategoryIconData('restaurant', 'رستوران', Icons.restaurant_rounded),
  CategoryIconData('coffee', 'قهوه', Icons.local_cafe_rounded, ['☕']),
  CategoryIconData(
      'transport', 'حمل‌ونقل', Icons.directions_bus_rounded, ['🚌']),
  CategoryIconData('car', 'خودرو', Icons.directions_car_rounded, ['🚗']),
  CategoryIconData('fuel', 'سوخت', Icons.local_gas_station_rounded, ['⛽']),
  CategoryIconData('taxi', 'تاکسی', Icons.local_taxi_rounded, ['🚕']),
  CategoryIconData('health', 'سلامت', Icons.health_and_safety_rounded, ['🩺']),
  CategoryIconData('medicine', 'دارو', Icons.medication_rounded, ['💊']),
  CategoryIconData('fitness', 'ورزش', Icons.fitness_center_rounded, ['🏋️']),
  CategoryIconData('entertainment', 'سرگرمی', Icons.movie_rounded, ['🎬']),
  CategoryIconData('gaming', 'بازی', Icons.sports_esports_rounded, ['🎮']),
  CategoryIconData('shopping', 'خرید', Icons.shopping_cart_rounded, ['🛒']),
  CategoryIconData('clothes', 'پوشاک', Icons.checkroom_rounded, ['👕']),
  CategoryIconData('bills', 'قبوض', Icons.receipt_long_rounded, ['🧾']),
  CategoryIconData('electricity', 'برق', Icons.electric_bolt_rounded, ['⚡']),
  CategoryIconData('water', 'آب', Icons.water_drop_rounded, ['💧']),
  CategoryIconData('internet', 'اینترنت', Icons.wifi_rounded, ['🌐']),
  CategoryIconData('mobile', 'موبایل', Icons.smartphone_rounded, ['📱', '📞']),
  CategoryIconData('home', 'خانه', Icons.home_rounded, ['🏠']),
  CategoryIconData('rent', 'اجاره', Icons.key_rounded, ['🔑']),
  CategoryIconData('education', 'آموزش', Icons.school_rounded, ['🎓']),
  CategoryIconData('books', 'کتاب', Icons.menu_book_rounded, ['📚']),
  CategoryIconData('travel', 'سفر', Icons.flight_rounded, ['✈️', '✈']),
  CategoryIconData('gift', 'هدیه', Icons.card_giftcard_rounded, ['🎁']),
  CategoryIconData('pets', 'حیوانات', Icons.pets_rounded, ['🐾']),
  CategoryIconData('subscriptions', 'اشتراک', Icons.autorenew_rounded, ['🔁']),
  CategoryIconData('salary', 'حقوق', Icons.payments_rounded, ['💵']),
  CategoryIconData('work', 'کار', Icons.work_rounded, ['💼']),
  CategoryIconData('savings', 'پس‌انداز', Icons.savings_rounded, ['🐷']),
  CategoryIconData(
      'investment', 'سرمایه‌گذاری', Icons.trending_up_rounded, ['📈']),
  CategoryIconData('other', 'سایر', Icons.category_rounded, ['💰', '💸']),
];

CategoryIconData resolveCategoryIcon(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return categoryIconChoices.last;
  for (final choice in categoryIconChoices) {
    if (choice.key == normalized ||
        choice.aliases.any((alias) => alias.toLowerCase() == normalized)) {
      return choice;
    }
  }
  return categoryIconChoices.last;
}

class CategoryIcon extends StatelessWidget {
  final String? value;
  final Color? color;
  final double size;

  const CategoryIcon({super.key, this.value, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) => Icon(
        resolveCategoryIcon(value).icon,
        color: color,
        size: size,
      );
}
