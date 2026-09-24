class MonthComparisonPresentation {
  final String text;
  final bool beneficial;
  final bool neutral;
  final bool increased;

  const MonthComparisonPresentation({
    required this.text,
    required this.beneficial,
    required this.neutral,
    required this.increased,
  });
}

MonthComparisonPresentation? presentNetSavingsComparison({
  required num currentNet,
  required num? previousNet,
  required String Function(num value) formatPercent,
}) {
  if (previousNet == null) return null;
  if (previousNet == 0) {
    return MonthComparisonPresentation(
      text: currentNet == 0
          ? 'پس‌انداز این ماه تغییری نسبت به ماه قبل ندارد'
          : 'ماه قبل پس‌انداز قابل مقایسه‌ای ثبت نشده',
      beneficial: false,
      neutral: true,
      increased: currentNet > 0,
    );
  }

  final change = ((currentNet - previousNet) / previousNet.abs()) * 100;
  final rounded = change.abs().round();
  if (rounded == 0) {
    return const MonthComparisonPresentation(
      text: 'پس‌انداز این ماه تقریباً برابر ماه قبل است',
      beneficial: false,
      neutral: true,
      increased: false,
    );
  }

  final increased = change > 0;
  return MonthComparisonPresentation(
    text:
        'پس‌انداز این ماه ${formatPercent(rounded)}٪ ${increased ? 'بیشتر' : 'کمتر'} از ماه قبل است',
    beneficial: increased,
    neutral: false,
    increased: increased,
  );
}
