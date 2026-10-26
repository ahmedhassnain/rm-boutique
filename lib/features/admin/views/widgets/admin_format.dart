import 'package:intl/intl.dart';

import '../../../../shared/models/order.dart';

/// Small text helpers shared by the admin screens, so money, dates and order
/// names look identical everywhere.

final NumberFormat adminMoney =
    NumberFormat.currency(symbol: '₪', decimalDigits: 0);

/// "Order 1a2b3c4d": the first 8 characters of the id, same as the other roles.
String adminOrderLabel(Order o) => 'Order ${o.id.substring(0, 8)}';

/// "5 Nov 2026"
String adminDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// "5 Nov 2026, 14:30"
String adminDateTime(DateTime d) =>
    DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());
