import 'models/profile.dart';

/// THE AGREED ORDER FLOW.
///
///   confirmed -> paid -> packed -> dispatched -> delivered
///
/// Same five values as the `order_status` type in supabase/schema.sql.
/// Never write these as plain strings anywhere else in the app.
/// The database refuses any other move (see guard_order_update in schema.sql).
enum OrderStatus {
  confirmed,
  paid,
  packed,
  dispatched,
  delivered;

  /// Value stored in the database.
  String get dbValue => name;

  /// Text shown to people.
  String get label => switch (this) {
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.paid => 'Paid',
        OrderStatus.packed => 'Packed',
        OrderStatus.dispatched => 'Dispatched',
        OrderStatus.delivered => 'Delivered',
      };

  static OrderStatus fromDb(String value) => OrderStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => throw ArgumentError('Unknown order status: $value'),
      );

  /// The next step in the flow, or null once delivered.
  OrderStatus? get next =>
      index + 1 < OrderStatus.values.length ? OrderStatus.values[index + 1] : null;

  /// Who is allowed to move an order OUT of this status.
  UserRole? get movedBy => switch (this) {
        OrderStatus.confirmed => UserRole.admin, // after verifying payment
        OrderStatus.paid => UserRole.admin,
        OrderStatus.packed => UserRole.admin, // needs a rider assigned
        OrderStatus.dispatched => UserRole.rider, // needs the delivery photo
        OrderStatus.delivered => null,
      };

  bool canBeAdvancedBy(UserRole role) => next != null && movedBy == role;
}
