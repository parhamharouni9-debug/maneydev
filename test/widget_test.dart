import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/widgets/amount_field.dart';

void main() {
  testWidgets('AmountField formats Persian input and reports its value',
      (tester) async {
    int? reportedAmount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountField(
            label: 'مبلغ',
            onChanged: (value) => reportedAmount = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '۱۲۵۰۰۰۰');
    await tester.pump();

    expect(reportedAmount, 1250000);
    expect(find.text('۱٬۲۵۰٬۰۰۰'), findsOneWidget);
    expect(find.text('یک میلیون و دویست و پنجاه هزار تومان'), findsOneWidget);
  });
}
