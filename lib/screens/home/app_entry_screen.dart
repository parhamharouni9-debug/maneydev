import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/app_state.dart';
import '../../utils/friendly_error.dart';
import '../onboarding/onboarding_screen.dart';
import 'home_shell.dart';

/// After a successful login/register/session-resume, this decides whether
/// the person needs the one-time onboarding (no months on record yet) or
/// can go straight to the dashboard.
class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  bool _loading = true;
  bool _needsOnboarding = false;
  num? _suggestedBalance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    // Defensive reset, mirroring the PWA's bootApp(): this screen mounts
    // fresh after every login/register/session-resume, so clearing cached
    // state here (in addition to on logout) guarantees no account's data
    // can ever leak into another account's view even if some future
    // logout path forgets to call AppState.reset() itself.
    AppState.instance.resetForAuthenticatedEntry();
    try {
      final months = await DataService.instance.listMonths();
      final currentKey = AppState.instance.monthKey;
      final currentExists = months.any((m) => m.monthKey == currentKey);

      if (currentExists) {
        _needsOnboarding = false;
      } else if (months.isEmpty) {
        // Very first month ever — ask for a starting balance from scratch.
        _needsOnboarding = true;
        _suggestedBalance = null;
      } else {
        // A later month starting fresh — carry over the most recent prior
        // month's ending balance (start balance + income - expense) as a
        // suggestion, same as the PWA.
        _needsOnboarding = true;
        final prev = months.first; // listMonths() is ordered month_key DESC
        final prevTx =
            await DataService.instance.listTransactions(prev.monthKey);
        final income = prevTx
            .where((t) => t.isIncome)
            .fold<num>(0, (a, t) => a + t.amount);
        final expense = prevTx
            .where((t) => !t.isIncome)
            .fold<num>(0, (a, t) => a + t.amount);
        _suggestedBalance = prev.startBalance + income - expense;
      }
    } catch (error) {
      if (!mounted) return;
      _error = friendlyAuthError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: AppColors.magenta, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _check, child: const Text('تلاش مجدد')),
              ],
            ),
          ),
        ),
      );
    }
    return _needsOnboarding
        ? OnboardingScreen(suggestedBalance: _suggestedBalance)
        : const HomeShell();
  }
}
