import 'profile.dart';

/// What a customer is writing about (riders do not tag their messages). Same two values as the `tag` column
/// of the `messages` table in supabase/chat.sql.
enum MessageTag {
  browsing('browsing', 'Browsing'),
  readyToOrder('ready_to_order', 'Ready to order');

  const MessageTag(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static MessageTag? fromDb(String? value) {
    for (final t in MessageTag.values) {
      if (t.dbValue == value) return t;
    }
    return null;
  }
}

/// One chat message. Every message belongs to one person's conversation with
/// the boutique ([memberId]: a customer or a rider) and was written either by
/// that person or by the admin ([fromAdmin]).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.memberId,
    required this.fromAdmin,
    required this.body,
    required this.createdAt,
    this.tag,
    this.readAt,
  });

  final String id;
  final String memberId;
  final bool fromAdmin;
  final String body;
  final MessageTag? tag;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        memberId: json['member_id'] as String,
        fromAdmin: json['from_admin'] as bool,
        body: json['body'] as String,
        tag: MessageTag.fromDb(json['tag'] as String?),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String).toLocal(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

/// Who a conversation is with, for the Inbox.
class ChatMember {
  const ChatMember({required this.name, required this.role});
  final String name;
  final UserRole role;

  bool get isRider => role == UserRole.rider;
}
