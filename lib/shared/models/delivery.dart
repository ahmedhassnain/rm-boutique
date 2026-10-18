class Delivery {
  const Delivery({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.photoPath,
    required this.deliveredAt,
    this.notes,
  });

  final String id;
  final String orderId;
  final String riderId;

  /// Path inside the private bucket `delivery-photos`.
  final String photoPath;
  final String? notes;
  final DateTime deliveredAt;

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        riderId: json['rider_id'] as String,
        photoPath: json['photo_path'] as String,
        notes: json['notes'] as String?,
        deliveredAt: DateTime.parse(json['delivered_at'] as String),
      );
}
