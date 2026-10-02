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
        builder: (context) => LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                return Scaffold(
                  backgroundColor: AppColors.bg,
                  body: wide
                      ? Row(children: [
                          _desktopNavigation(),
                          VerticalDivider(width: 1, color: AppColors.divider),
                          Expanded(
                            child:
                                IndexedStack(index: _index, children: _screens),
                          ),
                        ])
                      : IndexedStack(index: _index, children: _screens),
                  floatingActionButtonLocation: wide
                      ? FloatingActionButtonLocation.endFloat
                      : FloatingActionButtonLocation.centerDocked,
                  floatingActionButton: FloatingActionButton(
                    tooltip: 'ثبت تراکنش',
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    onPressed: () => showAddTransactionSheet(context),
                    child: const Icon(Icons.add_rounded, size: 30),
                  ),
                  bottomNavigationBar: wide ? null : _mobileNavigation(),
                );
              },
            ));
  }

  Widget _desktopNavigation() => SafeArea(
        child: NavigationRail(
          extended: true,
          minExtendedWidth: 216,
          backgroundColor: AppColors.cardBg,
          indicatorColor: AppColors.primary.withValues(alpha: 0.14),
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Text('پول من',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
          ),
          selectedIconTheme: IconThemeData(color: AppColors.primary),
          unselectedIconTheme: IconThemeData(color: AppColors.muted),
          selectedLabelTextStyle:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: Text('خانه')),
            NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: Text('تراکنش‌ها')),
            NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded),
                label: Text('گزارش‌ها')),
            NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: Text('دسته‌ها')),
          ],
        ),
      );

  Widget _mobileNavigation() => SafeArea(
        top: false,
        child: BottomAppBar(
          color: AppColors.cardBg,
          elevation: 0,
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
      );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _index == index;
    final color = selected ? AppColors.primary : AppColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _index = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
