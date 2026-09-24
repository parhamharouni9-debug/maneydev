import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/models/transaction.dart';
import 'package:pool_man/services/data_service.dart';
import 'package:pool_man/utils/jalali_helper.dart';
import 'package:pool_man/utils/transaction_date.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  test('Jalali dates serialize to exact Gregorian date-only', () {
    expect(
        TransactionCalendarDate.fromJalali(Jalali(1405, 1, 1)), '2026-03-21');
    expect(
        TransactionCalendarDate.fromJalali(Jalali(1404, 12, 29)), '2026-03-20');
    final value = TransactionCalendarDate.fromJalali(Jalali(1405, 1, 1));
    expect(value, isNot(contains('T')));
    expect(value, isNot(contains('Z')));
    expect(value, matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  test('first and last day of every Jalali month retain month_key', () {
    for (var month = 1; month <= 12; month++) {
      final first = Jalali(1405, month, 1);
      final last = Jalali(1405, month, first.monthLength);
      for (final selected in [first, last]) {
        final canonical = TransactionCalendarDate.fromJalali(selected);
        final parsed = TransactionCalendarDate.parse(canonical);
        expect(JalaliHelper.monthKeyFor(parsed.jalali),
            JalaliHelper.monthKeyFor(selected),
            reason: '${selected.year}-${selected.month}-${selected.day}');
        expect(parsed.jalali.day, selected.day);
      }
    }
  });

  test('Esfand leap/non-leap and Gregorian leap day round-trip', () {
    expect(Jalali(1399, 12, 1).monthLength, 30);
    expect(Jalali(1400, 12, 1).monthLength, 29);
    for (final selected in [Jalali(1399, 12, 30), Jalali(1400, 12, 29)]) {
      final back = TransactionCalendarDate.parse(
              TransactionCalendarDate.fromJalali(selected))
          .jalali;
      expect((back.year, back.month, back.day),
          (selected.year, selected.month, selected.day));
    }
    final leapDay = TransactionCalendarDate.parse('2024-02-29');
    expect(TransactionCalendarDate.fromJalali(leapDay.jalali), '2024-02-29');
    expect(() => TransactionCalendarDate.parse('2025-02-29'),
        throwsFormatException);
  });

  test('canonical date round-trip uses calendar components only', () {
    for (final value in [
      '2024-02-29',
      '2025-03-20',
      '2025-03-21',
      '2026-03-21'
    ]) {
      final parsed = TransactionCalendarDate.parse(value);
      expect(parsed.canonical, value);
      expect(TransactionCalendarDate.fromJalali(parsed.jalali), value);
    }
  });

  test('legacy timestamps preserve their leading historical Gregorian day', () {
    for (final value in [
      '2026-03-21T00:00:00',
      '2026-03-21T23:30:00Z',
      '2026-03-21T00:15:00+04:30',
      '2026-03-21T23:45:00-08:00',
    ]) {
      expect(TransactionCalendarDate.parse(value).canonical, '2026-03-21');
      expect(TransactionCalendarDate.isCanonical(value), isFalse);
      expect(
          MoneyTransaction.fromJson({
            'id': 'legacy',
            'month_key': '1405-01',
            'type': 'income',
            'amount': 1,
            'date': value,
            'recurring': false,
          }).date,
          value);
    }
  });

  test('only exact date-only values are canonical writes', () {
    expect(TransactionCalendarDate.isCanonical('2026-03-21'), isTrue);
    expect(TransactionCalendarDate.isCanonical('2026-3-21'), isFalse);
    expect(TransactionCalendarDate.isCanonical('2026-03-21T00:00:00'), isFalse);
  });

  test('mixed canonical and legacy sorting is by calendar day then stable id',
      () {
    final values = <MoneyTransaction>[
      _tx('b', '2026-03-21T23:59:00-08:00'),
      _tx('a', '2026-03-21'),
      _tx('c', '2026-03-20T23:59:00Z'),
    ]..sort((a, b) {
        final byDate = compareTransactionDates(b.date, a.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    expect(values.map((e) => e.id), ['a', 'b', 'c']);
  });

  test('shared Flutter payload fixture satisfies client month validation', () {
    final fixture = jsonDecode(
      File('test/fixtures/transaction_contract.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final transaction =
        MoneyTransaction.fromJson({'id': 'fixture', ...fixture});
    expect(() => validateTransactionMonth(transaction), returnsNormally);
    expect(transaction.toJson(), fixture);
  });
}

MoneyTransaction _tx(String id, String date) => MoneyTransaction(
      id: id,
      monthKey: '1405-01',
      type: 'income',
      amount: 1,
      date: date,
    );
