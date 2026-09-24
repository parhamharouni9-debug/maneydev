import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_theme.dart';
import '../utils/jalali_helper.dart';
import '../utils/persian_numbers.dart';

/// Shows a Jalali calendar picker and resolves with the picked [Jalali] date,
/// or null if the user backed out. Mirrors the PWA's jalali-calendar-grid.
Future<Jalali?> showJalaliDatePicker(BuildContext context, {Jalali? initial}) {
  return showModalBottomSheet<Jalali>(
    context: context,
    backgroundColor: AppColors.cardBg,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: _JalaliDatePickerSheet(initial: initial ?? Jalali.now()),
    ),
  );
}

class _JalaliDatePickerSheet extends StatefulWidget {
  final Jalali initial;
  const _JalaliDatePickerSheet({required this.initial});

  @override
  State<_JalaliDatePickerSheet> createState() => _JalaliDatePickerSheetState();
}

class _JalaliDatePickerSheetState extends State<_JalaliDatePickerSheet> {
  late int _year = widget.initial.year;
  late int _month = widget.initial.month;

  void _shiftMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m > 12) {
        m = 1;
        y++;
      }
      if (m < 1) {
        m = 12;
        y--;
      }
      _month = m;
      _year = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = Jalali.now();
    final grid = JalaliHelper.buildMonthGrid(_year, _month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: SingleChildScrollView(
        child: Column(
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
            // Header: prev/next month nav + title + close.
            // Nav buttons and the close button are kept clearly apart
            // (close sits alone on its own row) — this is exactly the
            // overlap bug we fixed in the PWA, avoided here by construction.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Matches the PWA's layout: this button (rendered on the visual
                // right, since the whole app is RTL) moves to the PREVIOUS month.
                IconButton(
                  icon: Icon(Icons.chevron_left, color: AppColors.text),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(
                  '${jalaliMonthNames[_month - 1]} ${PersianNumbers.toFa(_year)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                // Rendered on the visual left — moves to the NEXT month.
                IconButton(
                  icon: Icon(Icons.chevron_right, color: AppColors.text),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: jalaliWeekDaysShort
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: grid.map((cell) {
                if (cell == null) return const SizedBox.shrink();
                final isToday = cell.year == today.year &&
                    cell.month == today.month &&
                    cell.day == today.day;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).pop(cell),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: AppColors.cyan, width: 1.4)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      PersianNumbers.toFa(cell.day),
                      style: TextStyle(
                        color: isToday ? AppColors.cyan : AppColors.text,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('انصراف', style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
