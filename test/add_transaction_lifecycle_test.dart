import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/screens/home/add_transaction_sheet.dart';

void main() {
  testWidgets('disposing the sheet during a failed request is safe',
      (tester) async {
    final request = Completer<void>();
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTransactionSheet(
            initialType: 'income',
            saveTransaction: (_) {
              submitCount++;
              return request.future;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitCount, 1);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    request.completeError(Exception('technical detail'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(submitCount, 1);
  });
}
