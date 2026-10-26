import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/views/widgets/admin_order_card.dart';
import 'package:rm_boutique/features/admin/views/widgets/filter_chips.dart';
import 'package:rm_boutique/features/admin/views/widgets/summary_tile.dart';

import 'fakes.dart';

void main() {
  testWidgets('order card shows the order, customer, total and status',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminOrderCard(
          order: makeOrder(status: 'paid'),
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Order order-12'), findsOneWidget);
    expect(find.textContaining('Maheen Zubair'), findsOneWidget);
    expect(find.textContaining('900'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    await tester.tap(find.byType(AdminOrderCard));
    expect(tapped, true);
  });

  testWidgets('an urgent order shows its needed-by date', (tester) async {
    final soon = DateTime.now().add(const Duration(days: 1));
    final iso = soon.toIso8601String().substring(0, 10);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminOrderCard(
          order: makeOrder(neededBy: iso),
          onTap: () {},
        ),
      ),
    ));
    expect(find.textContaining('Needed by'), findsOneWidget);
  });

  testWidgets('filter chips report the tapped option', (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilterChips<String>(
          options: const ['All', 'Paid'],
          selected: 'All',
          labelOf: (s) => s,
          onSelected: (s) => picked = s,
        ),
      ),
    ));
    await tester.tap(find.text('Paid'));
    expect(picked, 'Paid');
  });

  testWidgets('summary tile shows its number and label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SummaryTile(value: '7', label: 'Need action')),
    ));
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Need action'), findsOneWidget);
  });
}
