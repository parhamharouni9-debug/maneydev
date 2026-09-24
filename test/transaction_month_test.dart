import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/models/transaction.dart';
import 'package:pool_man/services/api_client.dart';
import 'package:pool_man/services/data_service.dart';

MoneyTransaction transaction({
  required String monthKey,
  required String date,
}) =>
    MoneyTransaction(
      id: '',
      monthKey: monthKey,
      type: 'expense',
      amount: 1000,
      date: date,
    );

void main() {
  test('transaction month must match its selected date', () {
    expect(
      () => validateTransactionMonth(
        transaction(monthKey: '1405-05', date: '2026-08-01T12:00:00'),
      ),
      returnsNormally,
    );
  });

  test('mismatched transaction month is rejected before the API call', () {
    expect(
      () => validateTransactionMonth(
        transaction(monthKey: '1405-04', date: '2026-08-01T12:00:00'),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
