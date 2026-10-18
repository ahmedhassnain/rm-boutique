class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.screenshotPath,
    required this.verified,
    required this.flagged,
    this.amount,
    this.verifiedAt,
  });

  final String id;
  final String orderId;

  /// Path inside the private bucket `payment-proofs`.
  /// Get a viewable link with StorageRepository.signedUrl.
  final String screenshotPath;
  final double? amount;
  final bool verified;

  /// The admin marks a mismatch (wrong amount, fake or delayed transfer).
  final bool flagged;
  final DateTime? verifiedAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        screenshotPath: json['screenshot_path'] as String,
        amount: (json['amount'] as num?)?.toDouble(),
        verified: (json['verified'] as bool?) ?? false,
        flagged: (json['flagged'] as bool?) ?? false,
        verifiedAt: json['verified_at'] == null
            ? null
            : DateTime.parse(json['verified_at'] as String),
      );
}
