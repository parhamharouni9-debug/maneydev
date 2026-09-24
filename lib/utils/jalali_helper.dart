import 'package:shamsi_date/shamsi_date.dart';
import 'persian_numbers.dart';
import 'transaction_date.dart';

const List<String> jalaliMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

const List<String> jalaliWeekDaysShort = [
  'ش',
  'ی',
  'د',
  'س',
  'چ',
  'پ',
  'ج',
];

class JalaliHelper {
  /// month_key format used by the backend: "YYYY-MM" (Jalali year-month)
  static String monthKeyFor(Jalali j) =>
      '${j.year}-${j.month.toString().padLeft(2, '0')}';

  static String monthKeyForNow() => monthKeyFor(Jalali.now());

  static String monthLabelFor(Jalali j) =>
      '${jalaliMonthNames[j.month - 1]} ${PersianNumbers.toFa(j.year)}';

  /// Parse a month_key like "1403-05" into a Jalali (1st of month).
  static Jalali parseMonthKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return Jalali(y, m, 1);
  }

  static Jalali fromGregorian(DateTime dt) => Jalali.fromDateTime(dt);

  static DateTime toGregorian(Jalali j) => j.toDateTime();

  /// Format an ISO date string for list display, e.g. "۱۲ مرداد"
  static String formatShort(String isoDate) {
    final j = TransactionCalendarDate.parse(isoDate).jalali;
    return '${PersianNumbers.toFa(j.day)} ${jalaliMonthNames[j.month - 1]}';
  }

  static String formatFull(String isoDate) {
    final j = TransactionCalendarDate.parse(isoDate).jalali;
    return '${PersianNumbers.toFa(j.day)} ${jalaliMonthNames[j.month - 1]} ${PersianNumbers.toFa(j.year)}';
  }

  /// Build a 6x7 calendar grid (list of Jalali? — null for leading/trailing blanks)
  /// for the given Jalali month, week starting Saturday (شنبه) as in the PWA.
  static List<Jalali?> buildMonthGrid(int year, int month) {
    final first = Jalali(year, month, 1);
    final daysInMonth = first.monthLength;
    // shamsi_date's weekDay is 1=Saturday ... 7=Friday (Saturday-first week).
    // Shift to a 0-based Saturday=0 offset for the grid's leading blanks.
    final leading = (first.weekDay - 1) % 7;
    final cells = <Jalali?>[];
    for (int i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(Jalali(year, month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }
}
