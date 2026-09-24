import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/models/category.dart';
import 'package:pool_man/models/month.dart';
import 'package:pool_man/models/transaction.dart';
import 'package:pool_man/models/user.dart';
import 'package:pool_man/services/api_client.dart';

void main() {
  test('models accept numeric strings and common boolean encodings', () {
    final category = MoneyCategory.fromJson({
      'id': 12,
      'label': 'Food',
      'budget': '1250.5',
      'is_default': '1',
    });
    final month = MonthInfo.fromJson({
      'month_key': '1405-01',
      'month_label': 'Farvardin',
      'start_balance': '900',
    });
    final transaction = MoneyTransaction.fromJson({
      'id': 4,
      'month_key': '1405-01',
      'type': 'expense',
      'amount': '42.5',
      'date': '2026-03-21T00:00:00.000Z',
      'recurring': 'false',
    });

    expect(category.id, '12');
    expect(category.budget, 1250.5);
    expect(category.isDefault, isTrue);
    expect(month.startBalance, 900);
    expect(transaction.amount, 42.5);
    expect(transaction.recurring, isFalse);
  });

  test('required null and malformed numeric fields fail predictably', () {
    expect(
      () => AppUser.fromJson({'id': null, 'email': 'a@b.c', 'name': 'A'}),
      throwsFormatException,
    );
    expect(
      () => Goal.fromJson({'month_key': '1405-01', 'target_amount': 'bad'}),
      throwsFormatException,
    );
    expect(
      () => MoneyTransaction.fromJson({
        'id': '1',
        'month_key': '1405-01',
        'type': 'other',
        'amount': 1,
        'date': 'not-a-date',
      }),
      throwsFormatException,
    );
  });

  test('malformed API response shapes become ApiException', () {
    expect(() => apiJsonObject(null), throwsA(isA<ApiException>()));
    expect(
        () => apiJsonObjectList({'items': []}), throwsA(isA<ApiException>()));
    expect(
      () => apiJsonObjectList([
        {'id': 1},
        'bad',
      ]),
      throwsA(isA<ApiException>()),
    );
  });
}
