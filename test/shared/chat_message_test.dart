import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/shared/models/chat_message.dart';
import 'package:rm_boutique/shared/models/order.dart';

void main() {
  test('ChatMessage.fromJson reads a customer message with a tag', () {
    final m = ChatMessage.fromJson({
      'id': 'm1',
      'member_id': 'c1',
      'sender_id': 'c1',
      'from_admin': false,
      'body': 'Do you have the olive dress in M?',
      'tag': 'ready_to_order',
      'read_at': null,
      'created_at': '2026-10-31T10:00:00+00:00',
    });
    expect(m.fromAdmin, isFalse);
    expect(m.tag, MessageTag.readyToOrder);
    expect(m.isRead, isFalse);
    expect(m.body, startsWith('Do you have'));
  });

  test('ChatMessage.fromJson reads an admin reply that has been read', () {
    final m = ChatMessage.fromJson({
      'id': 'm2',
      'member_id': 'c1',
      'sender_id': 'a1',
      'from_admin': true,
      'body': 'Yes, it is in stock.',
      'tag': null,
      'read_at': '2026-10-31T10:05:00+00:00',
      'created_at': '2026-10-31T10:01:00+00:00',
    });
    expect(m.fromAdmin, isTrue);
    expect(m.tag, isNull);
    expect(m.isRead, isTrue);
  });

  test('MessageTag maps to and from the database values', () {
    expect(MessageTag.fromDb('browsing'), MessageTag.browsing);
    expect(MessageTag.fromDb('ready_to_order'), MessageTag.readyToOrder);
    expect(MessageTag.fromDb('nonsense'), isNull);
    expect(MessageTag.readyToOrder.dbValue, 'ready_to_order');
  });

  test('OrderItem reads the product photo path from the joined product', () {
    final o = Order.fromJson({
      'id': 'o1',
      'customer_id': 'c1',
      'status': 'paid',
      'delivery_address': 'Hebron',
      'total': 389,
      'created_at': '2026-10-20T10:00:00+00:00',
      'order_items': [
        {
          'id': 'i1',
          'order_id': 'o1',
          'variant_id': 'v1',
          'quantity': 1,
          'unit_price': 389,
          'product_variants': {
            'size': 'M',
            'colour': 'Olive',
            'products': {'name': 'Tatreez Evening Dress', 'image_path': 'p1/main.jpg'},
          },
        },
      ],
    });
    expect(o.items.single.imagePath, 'p1/main.jpg');
    expect(o.items.single.productName, 'Tatreez Evening Dress');
  });
}
