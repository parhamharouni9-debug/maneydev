import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/models/category.dart';
import 'package:pool_man/models/month.dart';
import 'package:pool_man/models/transaction.dart';
import 'package:pool_man/services/app_state.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  test('only the latest request generation can commit', () {
    final requests = RequestGeneration();
    final first = requests.next();
    final second = requests.next();

    expect(requests.isCurrent(first), isFalse);
    expect(requests.isCurrent(second), isTrue);
  });

  test('reset invalidates an in-flight request', () {
    final requests = RequestGeneration();
    final inFlight = requests.next();

    requests.invalidate();

    expect(requests.isCurrent(inFlight), isFalse);
  });

  test('refreshGoal does not commit after the selected month changes',
      () async {
    final response = Completer<Goal?>();
    final state = AppState.forTesting(
      goalLoader: (_) => response.future,
    )..selectedMonth = Jalali(1405, 1, 1);

    final request = state.refreshGoal();
    state.selectedMonth = Jalali(1405, 2, 1);
    response.complete(Goal(
      id: 'old-goal',
      monthKey: '1405-01',
      targetAmount: 100,
    ));
    await request;

    expect(state.goal, isNull);
  });

  test('addTransaction does not commit after the selected month changes',
      () async {
    final response = Completer<MoneyTransaction>();
    final state = AppState.forTesting(
      transactionCreator: (_) => response.future,
    )..selectedMonth = Jalali(1405, 1, 1);
    final transaction = MoneyTransaction(
      id: 'tx-1',
      monthKey: '1405-01',
      type: 'income',
      amount: 10,
      date: '2026-03-21T00:00:00.000',
    );

    final request = state.addTransaction(transaction);
    state.selectedMonth = Jalali(1405, 2, 1);
    response.complete(transaction);
    await request;

    expect(state.transactions, isEmpty);
  });

  test('account A category response cannot overwrite account B after logout',
      () async {
    final accountAResponse = Completer<List<MoneyCategory>>();
    final state = AppState.forTesting(
      categoryLoader: () => accountAResponse.future,
    );
    final accountBCategory = MoneyCategory(
      id: 'account-b',
      label: 'Account B',
      icon: 'B',
      color: '#000000',
    );

    final accountARequest = state.loadCategories();
    state.reset(); // Account A logs out.
    final accountBGeneration = state.beginAuthenticationTransition();
    expect(state.activateSession(accountBGeneration), isTrue);
    state.categories = [accountBCategory];

    accountAResponse.complete([
      MoneyCategory(
        id: 'account-a',
        label: 'Account A',
        icon: 'A',
        color: '#ffffff',
      ),
    ]);
    await accountARequest;

    expect(state.categories, orderedEquals([accountBCategory]));
  });
}
