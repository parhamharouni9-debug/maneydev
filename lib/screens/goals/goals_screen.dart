import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/goals_service.dart';
import '../../models/month.dart';
import '../../utils/persian_numbers.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/animated_goal_bar.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../utils/friendly_error.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _app = AppState.instance;
  Goal? _goal;
  bool _loading = true;
  bool _celebrated = false;
  String? _error;
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goal = await GoalsService.instance.getGoal(_app.monthKey);
      if (!mounted) return;
      setState(() => _goal = goal);
      _maybeCelebrate();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Fires the confetti burst exactly once per screen visit when the
  /// goal is freshly reached — not on every rebuild.
  void _maybeCelebrate() {
    // See the fix note near line ~81: use the running balance, not just
    // this month's income-expense flow.
    final netSaved = _app.balance;
    final target = _goal?.targetAmount ?? 0;
    final reached = target > 0 && netSaved >= target;
    if (reached && !_celebrated) {
      _celebrated = true;
      _confetti.play();
    }
  }

  Future<void> _openEditor() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _GoalEditorSheet(existing: _goal, monthKey: _app.monthKey),
    );
    await _load();
    await _app.refreshGoal();
  }

  Future<void> _delete() async {
    if (_goal == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await GoalsService.instance.deleteGoal(_app.monthKey);
      await _app.refreshGoal();
      if (mounted) setState(() => _goal = null);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX (goal progress bug): "amount saved toward the goal" must be
    // the running, carried-forward balance — not just this month's
    // income-minus-expense, which resets every month and has no direct
    // relationship to a multi-month savings target. Using income-expense
    // here was exactly what produced impossible-looking numbers like
    // "1,440,000 از هدف" when the person's real balance was 2,366,000.
    final netSaved = _app.balance;
    final target = _goal?.targetAmount ?? 0;
    final ratio = target > 0 ? (netSaved / target).clamp(0, 1.5) : 0.0;
    final reached = target > 0 && netSaved >= target;

    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(title: Text('هدف مالی ${_app.monthLabel}')),
              body: Stack(
                children: [
                  _loading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: AppColors.cyan))
                      : _error != null
                          ? Center(
                              child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                TextButton(
                                    onPressed: _load,
                                    child: const Text('تلاش دوباره')),
                              ],
                            ))
                          : Padding(
                              padding: const EdgeInsets.all(18),
                              child: _goal == null
                                  ? _emptyState()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(22),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBg,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: (reached
                                                      ? AppColors.green
                                                      : AppColors.cyan)
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              if (_goal!.label != null &&
                                                  _goal!.label!.isNotEmpty) ...[
                                                Text(_goal!.label!,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    )),
                                                const SizedBox(height: 10),
                                              ],
                                              Text(
                                                '${PersianNumbers.formatAmount(netSaved)} از ${PersianNumbers.formatAmount(target)} تومان',
                                                style: TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 14),
                                              AnimatedGoalBar(
                                                value: ratio.toDouble(),
                                                color: reached
                                                    ? AppColors.green
                                                    : AppColors.cyan,
                                                height: 12,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                reached
                                                    ? 'هدف این ماه رو زدی 🎉'
                                                    : '${PersianNumbers.toFa((ratio * 100).clamp(0, 100).round())}٪ پیش رفتی',
                                                style: TextStyle(
                                                  color: reached
                                                      ? AppColors.green
                                                      : AppColors.cyan,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        OutlinedButton(
                                          onPressed: _openEditor,
                                          child: const Text('ویرایش هدف'),
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton(
                                          onPressed: _delete,
                                          child: Text('حذف هدف',
                                              style: TextStyle(
                                                  color: AppColors.magenta)),
                                        ),
                                      ],
                                    ),
                            ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      gravity: 0.25,
                      colors: [
                        AppColors.cyan,
                        AppColors.green,
                        AppColors.warning,
                        AppColors.magenta
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: _goal == null
                  ? FloatingActionButton.extended(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.bg,
                      onPressed: _openEditor,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('تعیین هدف'),
                    )
                  : null,
            ));
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, color: AppColors.muted, size: 48),
          const SizedBox(height: 12),
          Text('هنوز هدفی برای این ماه تعیین نکردی',
              style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _GoalEditorSheet extends StatefulWidget {
  final Goal? existing;
  final String monthKey;
  const _GoalEditorSheet({this.existing, required this.monthKey});

  @override
  State<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<_GoalEditorSheet> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  int? _amount;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = widget.existing?.targetAmount.round();
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amount == null || _amount! <= 0) {
      setState(() => _error = 'مبلغ هدف را وارد کن');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await GoalsService.instance.saveGoal(
        monthKey: widget.monthKey,
        targetAmount: _amount!,
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هدف پس‌انداز این ماه',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            AmountField(
                label: 'مبلغ هدف',
                initialValue: _amount,
                onChanged: (v) => _amount = v),
            const SizedBox(height: 14),
            TextField(
                controller: _label,
                decoration:
                    const InputDecoration(labelText: 'عنوان (اختیاری)')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: TextStyle(color: AppColors.magenta, fontSize: 12.5)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.bg))
                  : const Text('ذخیره هدف'),
            ),
          ],
        ),
      ),
    );
  }
}
