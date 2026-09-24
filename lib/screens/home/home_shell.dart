import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../home/summary_screen.dart';
import '../categories/categories_screen.dart';
import '../../widgets/theme_rebuilder.dart';
import 'add_transaction_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Matches the approved reference: خانه, تراکنش‌ها, [+], گزارش‌ها, دسته‌ها.
  // "تاریخچه" (month history) moved into Settings — it's no longer one of
  // the five bottom-nav destinations.
  final _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const SummaryScreen(),
    const CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              body: IndexedStack(index: _index, children: _screens),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                onPressed: () => showAddTransactionSheet(context),
                child: const Icon(Icons.add_rounded, size: 30),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                // Explicit safe-area wrap (not a hardcoded pixel offset) so the
                // nav bar and centered "+" button never sit under/behind a
                // gesture nav bar or 3-button nav bar — this is the case on
                // several MIUI/Xiaomi devices where the raw BottomAppBar height
                // alone isn't enough.
                child: BottomAppBar(
                  color: AppColors.cardBg,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.28),
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(0, Icons.home_rounded, 'خانه'),
                      _navItem(1, Icons.receipt_long_rounded, 'تراکنش‌ها'),
                      const SizedBox(width: 48),
                      _navItem(2, Icons.pie_chart_rounded, 'گزارش‌ها'),
                      _navItem(3, Icons.grid_view_rounded, 'دسته‌ها'),
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _index = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
