import 'dart:typed_data';

import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/repositories/order_repository.dart';
import 'package:rm_boutique/shared/repositories/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A real-but-unused client, only so the repositories' constructors never
/// touch the uninitialised global `supabase` singleton in tests.
SupabaseClient _dummyClient() =>
    SupabaseClient('https://example.supabase.co', 'anon-key');

/// Stands in for OrderRepository: returns whatever the test puts in
/// [ordersToStream] / [orderToReturn] instead of calling Supabase.
class FakeOrderRepository extends OrderRepository {
  FakeOrderRepository() : super(client: _dummyClient());

  List<Order> ordersToStream = const [];
  Object? streamError;
  Order? orderToReturn;
  Object? fetchError;

  @override
  Stream<List<Order>> watchOrders() =>
      streamError != null ? Stream.error(streamError!) : Stream.value(ordersToStream);

  @override
  Stream<Order> watchOrder(String id) =>
      orderToReturn == null ? const Stream.empty() : Stream.value(orderToReturn!);

  @override
  Future<Order> fetchOrder(String id) async {
    if (fetchError != null) throw fetchError!;
    return orderToReturn!;
  }
}

/// Stands in for StorageRepository: records calls instead of hitting
/// Supabase Storage.
class FakeStorageRepository extends StorageRepository {
  FakeStorageRepository() : super(client: _dummyClient());

  bool uploadCalled = false;
  String? lastOrderId;
  Uint8List? lastBytes;
  Object? uploadError;

  @override
  Future<void> uploadDeliveryProof({
    required String orderId,
    required Uint8List bytes,
    String? notes,
  }) async {
    if (uploadError != null) throw uploadError!;
    uploadCalled = true;
    lastOrderId = orderId;
    lastBytes = bytes;
  }

  @override
  Future<String> signedUrl(String bucket, String path) async =>
      'https://example.supabase.co/$bucket/$path?signed=1';
}
