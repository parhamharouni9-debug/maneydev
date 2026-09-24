import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../utils/jalali_helper.dart';
import '../../utils/persian_numbers.dart';
import '../../utils/friendly_error.dart';
import '../../utils/transaction_date.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/jalali_date_picker.dart';
import '../../widgets/category_icon.dart';

Future<void> showAddTransactionSheet(BuildContext context,
    {String initialType = 'expense'}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    useSafeArea: true,
    builder: (_) => AddTransactionSheet(initialType: initialType),
  );
}

class AddTransactionSheet extends StatefulWidget {
  final String initialType;
  final Future<void> Function(MoneyTransaction transaction)? saveTransaction;
  const AddTransactionSheet({
    super.key,
    this.initialType = 'expense',
    this.saveTransaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late String _type = widget.initialType;
  int? _amount;
  MoneyCategory? _category;
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;
  Jalali _date = Jalali.now();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showJalaliDatePicker(context, initial: _date);
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_amount == null || _amount! <= 0) {
      setState(() => _error = 'مبلغ را وارد کن');
      return;
    }
    if (_type == 'expense' && _category == null) {
      setState(() => _error = 'یک دسته انتخاب کن');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final app = AppState.instance;
      final transaction = MoneyTransaction(
        id: '', // server assigns the real id
        monthKey: JalaliHelper.monthKeyFor(_date),
        type: _type,
        amount: _amount!,
        category: _type == 'expense' ? _category?.id : null,
        source: _type == 'income'
            ? (_note.text.trim().isEmpty ? null : _note.text.trim())
            : null,
        note: _type == 'expense'
            ? (_note.text.trim().isEmpty ? null : _note.text.trim())
            : null,
        date: TransactionCalendarDate.fromJalali(_date),
      );
      if (widget.saveTransaction != null) {
        await widget.saveTransaction!(transaction);
      } else {
        await app.addTransaction(transaction);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        media.padding.bottom;
    final maxSheetHeight =
        (availableHeight - 20).clamp(320.0, media.size.height).toDouble();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: media.viewInsets.bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.muted.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Income / expense toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Expanded(
                              child: _typeChip(
                                  'expense', 'خرج', AppColors.magenta)),
                          Expanded(
                              child: _typeChip(
                                  'income', 'درآمد', AppColors.green)),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      AmountField(
                        label: _type == 'expense' ? 'مبلغ خرج' : 'مبلغ درآمد',
                        onChanged: (v) => setState(() => _amount = v),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('تاریخ',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.cyan),
                              Text(
                                '${PersianNumbers.toFa(_date.day)} ${jalaliMonthNames[_date.month - 1]} ${PersianNumbers.toFa(_date.year)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (JalaliHelper.monthKeyFor(_date) !=
                          AppState.instance.monthKey) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⚠️ تراکنش در ماه مربوط به تاریخ انتخاب‌شده ثبت میشه',
                          style:
                              TextStyle(color: AppColors.amber, fontSize: 11.5),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (_type == 'expense') ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('دسته',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: app.categories.map((c) {
                            final selected = _category?.id == c.id;
                            final color = AppTheme.categoryColor(c.color);
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color:
                                                color.withValues(alpha: 0.28),
                                            blurRadius: 12,
                                            spreadRadius: 0)
                                      ]
                                    : [],
                              ),
                              child: ChoiceChip(
                                avatar: CategoryIcon(
                                  value: c.icon,
                                  color: selected ? color : AppColors.muted,
                                  size: 18,
                                ),
                                label: Text(c.label),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _category = c),
                                selectedColor: color.withValues(alpha: 0.22),
                                backgroundColor: AppColors.cardBg,
                                labelStyle: TextStyle(
                                  color: selected ? color : AppColors.text,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                side: BorderSide(
                                    color: selected
                                        ? color.withValues(alpha: 0.6)
                                        : AppColors.divider,
                                    width: selected ? 1.3 : 1),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                      TextField(
                        controller: _note,
                        decoration: InputDecoration(
                          labelText: _type == 'income'
                              ? 'منبع (اختیاری)'
                              : 'یادداشت (اختیاری)',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: TextStyle(
                                color: AppColors.magenta, fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _type == 'expense' ? AppColors.magenta : AppColors.green,
                ),
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.bg))
                    : Text(_type == 'expense' ? 'ثبت خرج' : 'ثبت درآمد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label, Color color) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() {
        _type = value;
        _error = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              color: selected ? color : AppColors.muted,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}
