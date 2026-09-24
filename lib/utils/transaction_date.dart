import 'package:shamsi_date/shamsi_date.dart';

/// Calendar-date contract used for transactions.
///
/// New writes are Gregorian `YYYY-MM-DD`. During the compatibility window,
/// legacy ISO timestamps are accepted for reads, but their leading Gregorian
/// date is treated as the historical calendar day. No UTC/local conversion is
/// performed when deriving the displayed Jalali date or month key.
class TransactionCalendarDate {
  const TransactionCalendarDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  String get canonical => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  Jalali get jalali => Gregorian(year, month, day).toJalali();

  static String fromJalali(Jalali date) {
    final gregorian = date.toGregorian();
    return TransactionCalendarDate(
      gregorian.year,
      gregorian.month,
      gregorian.day,
    ).canonical;
  }

  static TransactionCalendarDate parse(String value) {
    if (value.length < 10) {
      throw const FormatException('Invalid transaction date');
    }
    final leading = value.substring(0, 10);
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(leading);
    if (match == null) throw const FormatException('Invalid transaction date');
    final result = TransactionCalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (!_isValidGregorian(result.year, result.month, result.day)) {
      throw const FormatException('Invalid transaction date');
    }
    if (value.length != 10 && !_isSupportedLegacyTimestamp(value)) {
      throw const FormatException('Invalid transaction date');
    }
    return result;
  }

  static bool isCanonical(String value) {
    try {
      return parse(value).canonical == value;
    } on FormatException {
      return false;
    }
  }

  static bool _isSupportedLegacyTimestamp(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) return false;
    return DateTime.tryParse(value) != null;
  }

  static bool _isValidGregorian(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var maxDay = lengths[month - 1];
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    if (month == 2 && leap) maxDay = 29;
    return day <= maxDay;
  }
}

int compareTransactionDates(String left, String right) =>
    TransactionCalendarDate.parse(left)
        .canonical
        .compareTo(TransactionCalendarDate.parse(right).canonical);
