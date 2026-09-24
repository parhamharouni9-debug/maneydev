import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../utils/persian_numbers.dart';
import '../../widgets/amount_field.dart';
import '../home/home_shell.dart';
import '../../widgets/theme_rebuilder.dart';

/// Shown whenever the current Jalali month doesn't have a record yet —
/// mirrors the PWA's onboarding modal:
///  - First month ever (no prior months at all): ask for the starting
///    balance directly.
///  - Any later month: show what was carried over from the previous
///    month and let the person add or subtract from it, rather than
///    re-entering their whole balance from scratch.
class OnboardingScreen extends StatefulWidget {
  /// Ending balance of the most recent previous month, or null if this is
  /// the very first month the person has ever used the app for.
  final num? suggestedBalance;
  const OnboardingScreen({super.key, this.suggestedBalance});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int?
      _amount; // plain total (first-ever month) OR signed adjustment (carry-over)
  bool _saving = false;
  String? _error;

  bool get _hasCarry => (widget.suggestedBalance ?? 0) > 0;

  num get _previewTotal {
    final carry = widget.suggestedBalance ?? 0;
    if (_hasCarry) return (carry + (_amount ?? 0)).clamp(0, double.infinity);
    return _amount ?? 0;
  }

  Future<void> _continue({bool skip = false}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final app = AppState.instance;
      await app.loadCategories();
      final num startBalance =
          skip ? (widget.suggestedBalance ?? 0) : _previewTotal;
      await app.goToMonth(app.selectedMonth);
      if (startBalance != 0) {
        await app.setStartBalance(startBalance);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      Text(_hasCarry ? 'شروع ماه جدید 🎉' : 'خوش اومدی 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cyan,
                          )),
                      const SizedBox(height: 10),
                      if (_hasCarry) ...[
                        Text(
                          'از ماه قبل ${PersianNumbers.formatAmount(widget.suggestedBalance!)} تومان برات مونده.',
                          style: TextStyle(
                              color: AppColors.text, fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'چیزی هست که بخوای بهش اضافه یا ازش کم کنی؟ اگه نه، همینطوری رد کن.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13.5,
                              height: 1.6),
                        ),
                      ] else
                        Text(
                          'قبل از شروع، موجودی فعلیت رو وارد کن تا حساب و کتاب این ماه درست باشه. اگه نمی‌دونی، می‌تونی رد کنی و بعداً از تنظیمات اضافه‌ش کنی.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13.5,
                              height: 1.6),
                        ),
                      const SizedBox(height: 30),
                      AmountField(
                        label: _hasCarry
                            ? 'اضافه/کم کردن (با - شروع کن برای کم کردن)'
                            : 'موجودی فعلی',
                        allowNegative: _hasCarry,
                        onChanged: (v) => setState(() => _amount = v),
                      ),
                      if (_hasCarry) ...[
                        const SizedBox(height: 10),
                        Text(
                          'موجودی این ماه: ${PersianNumbers.formatAmount(_previewTotal)} تومان',
                          style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: TextStyle(
                                color: AppColors.magenta, fontSize: 12.5)),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _continue(),
                        child: _saving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bg))
                            : Text(_hasCarry ? 'شروع ماه' : 'شروع کن'),
                      ),
                      if (!_hasCarry) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _saving ? null : () => _continue(skip: true),
                          child: Text('رد کردن، بعداً وارد می‌کنم',
                              style: TextStyle(color: AppColors.muted)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ));
  }
}
