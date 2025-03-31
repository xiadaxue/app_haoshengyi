import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/screens/home/home_page.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';

void main() {
  testWidgets('HomePage显示正确的标题', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => TransactionProvider(),
          child: HomePage(),
        ),
      ),
    );

    expect(find.text('好生意记账本'), findsOneWidget);
  });

  // 添加更多测试...
}
