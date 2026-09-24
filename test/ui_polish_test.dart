import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/screens/auth/login_screen.dart';
import 'package:pool_man/screens/home/add_transaction_sheet.dart';
import 'package:pool_man/screens/home/dashboard_screen.dart';
import 'package:pool_man/screens/home/summary_screen.dart';
import 'package:pool_man/models/category.dart';
import 'package:pool_man/models/transaction.dart';
import 'package:pool_man/services/app_state.dart';
import 'package:pool_man/theme/app_theme.dart';
import 'package:pool_man/utils/month_comparison_presentation.dart';
import 'package:pool_man/utils/persian_numbers.dart';
import 'package:pool_man/widgets/auth_background.dart';
import 'package:pool_man/widgets/category_icon.dart';

Widget _app(Widget child, {MediaQueryData? mediaQuery}) => MaterialApp(
      locale: const Locale('fa', 'IR'),
      home: MediaQuery(
        data: mediaQuery ?? const MediaQueryData(size: Size(360, 720)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );

void main() {
  tearDown(() {
    AppState.instance.transactions = [];
    AppState.instance.categories = [];
  });

  test('month comparison explains net savings direction and zero baseline', () {
    final better = presentNetSavingsComparison(
      currentNet: 200,
      previousNet: 100,
      formatPercent: PersianNumbers.toFa,
    );
    expect(better?.text, 'پس‌انداز این ماه ۱۰۰٪ بیشتر از ماه قبل است');
    expect(better?.beneficial, isTrue);

    final worse = presentNetSavingsComparison(
      currentNet: 50,
      previousNet: 100,
      formatPercent: PersianNumbers.toFa,
    );
    expect(worse?.text, 'پس‌انداز این ماه ۵۰٪ کمتر از ماه قبل است');
    expect(worse?.beneficial, isFalse);

    final zeroBaseline = presentNetSavingsComparison(
      currentNet: 50,
      previousNet: 0,
      formatPercent: PersianNumbers.toFa,
    );
    expect(zeroBaseline?.neutral, isTrue);
    expect(zeroBaseline?.text, contains('قابل مقایسه'));
  });

  test('category palette is broad, distinct, and keeps legacy colors valid',
      () {
    expect(categoryColorChoices.length, inInclusiveRange(12, 18));
    expect(categoryColorChoices.toSet().length, categoryColorChoices.length);
    expect(categoryColorChoices, contains('#ff6b35'));
    expect(AppTheme.categoryColor('#00e6ff'), const Color(0xFF00E6FF));
  });

  test('category icon maps legacy emoji and safely falls back', () {
    expect(resolveCategoryIcon('🍕').key, 'food');
    expect(resolveCategoryIcon('🚌').key, 'transport');
    expect(resolveCategoryIcon('unknown-backend-value').key, 'other');
    expect(resolveCategoryIcon(null).icon, Icons.category_rounded);
  });

  testWidgets('legacy emoji category renders as a vector icon', (tester) async {
    await tester.pumpWidget(_app(const CategoryIcon(value: '💊')));

    expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    expect(find.text('💊'), findsNothing);
  });

  testWidgets('transaction CTA stays above system navigation safe area',
      (tester) async {
    const bottomInset = 48.0;
    await tester.pumpWidget(_app(
      const Scaffold(body: AddTransactionSheet(initialType: 'income')),
      mediaQuery: const MediaQueryData(
        size: Size(360, 640),
        padding: EdgeInsets.only(bottom: bottomInset),
        viewPadding: EdgeInsets.only(bottom: bottomInset),
      ),
    ));

    final button = find.widgetWithText(ElevatedButton, 'ثبت درآمد');
    expect(button, findsOneWidget);
    expect(
        tester.getBottomRight(button).dy, lessThanOrEqualTo(640 - bottomInset));
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction CTA stays visible above an open keyboard',
      (tester) async {
    const keyboardInset = 280.0;
    await tester.pumpWidget(_app(
      const Scaffold(body: AddTransactionSheet(initialType: 'income')),
      mediaQuery: const MediaQueryData(
        size: Size(360, 640),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
    ));

    final button = find.widgetWithText(ElevatedButton, 'ثبت درآمد');
    expect(button, findsOneWidget);
    expect(
      tester.getBottomRight(button).dy,
      lessThanOrEqualTo(640 - keyboardInset),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth layout remains scrollable on a short large-text screen',
      (tester) async {
    await tester.pumpWidget(_app(
      const LoginScreen(mascotOverride: SizedBox(height: 160)),
      mediaQuery: const MediaQueryData(
        size: Size(360, 640),
        textScaler: TextScaler.linear(1.3),
        padding: EdgeInsets.only(top: 24, bottom: 24),
      ),
    ));
    await tester.pump();

    expect(find.byType(AuthBackground), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth background lifecycle respects reduced motion',
      (tester) async {
    await tester.pumpWidget(_app(
      const AuthBackground(child: SizedBox.expand()),
      mediaQuery: const MediaQueryData(
        size: Size(360, 720),
        disableAnimations: true,
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard exposes the primary financial hierarchy',
      (tester) async {
    await tester.pumpWidget(_app(
      const DashboardScreen(),
      mediaQuery: const MediaQueryData(
        size: Size(360, 720),
        textScaler: TextScaler.linear(1.3),
      ),
    ));
    await tester.pump();

    expect(find.text('موجودی این ماه'), findsOneWidget);
    expect(find.text('درآمد'), findsOneWidget);
    expect(find.text('هزینه'), findsOneWidget);
    expect(find.text('بودجه باقی‌مانده'), findsOneWidget);
    expect(find.byType(FittedBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports has a stable empty layout without overflow',
      (tester) async {
    await tester.pumpWidget(_app(const SummaryScreen()));
    await tester.pump();

    expect(find.textContaining('گزارش‌ها'), findsOneWidget);
    expect(find.text('هنوز خرجی برای نمایش نیست'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports explains a single category with amount and share',
      (tester) async {
    AppState.instance.categories = [
      MoneyCategory(id: 'food', label: 'خوراک', icon: 'food', color: '#ff6b35'),
    ];
    AppState.instance.transactions = [
      MoneyTransaction(
        id: 'one',
        monthKey: '1405-06',
        type: 'expense',
        amount: 5000,
        category: 'food',
        date: '2026-08-30',
      ),
    ];

    await tester.pumpWidget(_app(const SummaryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('کل هزینه'), findsOneWidget);
    expect(find.text('۱۰۰٪ از هزینه‌ها'), findsOneWidget);
    expect(find.text('خوراک'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports sorts and labels multiple category shares',
      (tester) async {
    AppState.instance.categories = [
      MoneyCategory(id: 'food', label: 'خوراک', icon: 'food', color: '#ff6b35'),
      MoneyCategory(
          id: 'travel', label: 'سفر', icon: 'travel', color: '#3b82f6'),
    ];
    AppState.instance.transactions = [
      MoneyTransaction(
          id: 'one',
          monthKey: '1405-06',
          type: 'expense',
          amount: 7500,
          category: 'food',
          date: '2026-08-30'),
      MoneyTransaction(
          id: 'two',
          monthKey: '1405-06',
          type: 'expense',
          amount: 2500,
          category: 'travel',
          date: '2026-08-29'),
    ];

    await tester.pumpWidget(_app(const SummaryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('۷۵٪ از هزینه‌ها'), findsOneWidget);
    expect(find.text('۲۵٪ از هزینه‌ها'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
