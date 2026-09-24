/// Utilities for Persian digit conversion and number-to-words,
/// ported from the original PWA's JS helpers.
class PersianNumbers {
  static const _enToFa = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };
  static const _faToEn = {
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    // Arabic-Indic digits too (some mobile keyboards emit these)
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };

  /// Convert any ASCII/Arabic-Indic digit string to Persian digits.
  static String toFa(Object? value) {
    final s = value?.toString() ?? '';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      buf.write(_enToFa[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Normalize any Persian/Arabic-Indic digits in a string down to ASCII.
  /// Mirrors the mobile-keyboard digit-normalization fix from the web app.
  static String toEn(String value) {
    final buf = StringBuffer();
    for (final ch in value.split('')) {
      buf.write(_faToEn[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Parse a user-entered amount string (possibly Persian digits,
  /// possibly with thousands separators) into an int (Toman/Rial units).
  static int? parseAmount(String raw) {
    final normalized = toEn(raw).replaceAll(RegExp(r'[,\s٬]'), '');
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  /// Same as [parseAmount] but allows a leading '-' (ASCII or the fullwidth
  /// '−' minus sign some keyboards emit), for signed adjustment fields like
  /// "add or subtract from last month's carried-over balance".
  static int? parseSignedAmount(String raw) {
    var s = toEn(raw).replaceAll(RegExp(r'[,\s٬]'), '');
    if (s.isEmpty) return null;
    final negative = s.startsWith('-') || s.startsWith('−');
    if (negative) s = s.substring(1);
    final n = int.tryParse(s);
    if (n == null) return null;
    return negative ? -n : n;
  }

  /// Format an integer with thousands separators and Persian digits,
  /// e.g. 1250000 -> "۱٬۲۵۰٬۰۰۰"
  static String formatAmount(num value) {
    final isNegative = value < 0;
    final intVal = value.abs().round();
    final s = intVal.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('٬');
      buf.write(s[i]);
    }
    final formatted = toFa(buf.toString());
    return isNegative ? '−$formatted' : formatted;
  }

  static const _ones = [
    '',
    'یک',
    'دو',
    'سه',
    'چهار',
    'پنج',
    'شش',
    'هفت',
    'هشت',
    'نه',
    'ده',
    'یازده',
    'دوازده',
    'سیزده',
    'چهارده',
    'پانزده',
    'شانزده',
    'هفده',
    'هجده',
    'نوزده',
  ];
  static const _tens = [
    '',
    '',
    'بیست',
    'سی',
    'چهل',
    'پنجاه',
    'شصت',
    'هفتاد',
    'هشتاد',
    'نود',
  ];
  static const _hundreds = [
    '',
    'صد',
    'دویست',
    'سیصد',
    'چهارصد',
    'پانصد',
    'ششصد',
    'هفتصد',
    'هشتصد',
    'نهصد',
  ];
  static const _scales = ['', 'هزار', 'میلیون', 'میلیارد', 'تریلیون'];

  static String _threeDigits(int n) {
    final parts = <String>[];
    final h = n ~/ 100;
    final rem = n % 100;
    if (h > 0) parts.add(_hundreds[h]);
    if (rem > 0) {
      if (rem < 20) {
        parts.add(_ones[rem]);
      } else {
        final t = rem ~/ 10;
        final o = rem % 10;
        parts.add(o > 0 ? '${_tens[t]} و ${_ones[o]}' : _tens[t]);
      }
    }
    return parts.join(' و ');
  }

  /// Convert an integer amount into Persian words, e.g. 1250000 -> "یک میلیون و دویست و پنجاه هزار"
  static String toWords(int value) {
    if (value == 0) return 'صفر';
    final isNegative = value < 0;
    var n = value.abs();

    final groups = <int>[];
    while (n > 0) {
      groups.add(n % 1000);
      n ~/= 1000;
    }

    final parts = <String>[];
    for (int i = groups.length - 1; i >= 0; i--) {
      final g = groups[i];
      if (g == 0) continue;
      final words = _threeDigits(g);
      parts.add(i > 0 ? '$words ${_scales[i]}' : words);
    }

    final result = parts.join(' و ');
    return isNegative ? 'منفی $result' : result;
  }

  /// Full "amount in words" with currency suffix, matching the PWA's helper text.
  static String toWordsToman(int value) => '${toWords(value)} تومان';
}
