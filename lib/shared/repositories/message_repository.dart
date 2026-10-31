import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../models/chat_message.dart';
import '../models/profile.dart';

/// All chat reads and writes. Row Level Security decides who sees what, so
/// the same calls are safe for everyone:
///   customer or rider -> only their own conversation with the boutique,
///   admin -> every conversation.
class MessageRepository {
  MessageRepository({SupabaseClient? client}) : _db = client ?? supabase;
  final SupabaseClient _db;

  /// Live messages of one person's conversation, oldest first.
  Stream<List<ChatMessage>> watchThread(String memberId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('member_id', memberId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  /// Admin: live messages of every conversation, oldest first. The Inbox
  /// groups them by customer.
  Stream<List<ChatMessage>> watchAll() => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  /// Sends one message into [memberId]'s conversation. A customer or rider
  /// passes their own id (a customer may set a [tag]); the admin passes
  /// [fromAdmin] true and the id of the person they are answering.
  /// Throws PostgrestException if the database refuses it.
  Future<void> send({
    required String memberId,
    required String body,
    required bool fromAdmin,
    MessageTag? tag,
  }) async {
    await _db.from('messages').insert({
      'member_id': memberId,
      'from_admin': fromAdmin,
      'body': body.trim(),
      if (!fromAdmin && tag != null) 'tag': tag.dbValue,
    });
  }

  /// Marks the other side's messages in this conversation as read.
  Future<void> markRead(String memberId) async {
    await _db.rpc('mark_thread_read', params: {'p_member': memberId});
  }

  /// Names and roles for the Inbox: person id -> who they are.
  Future<Map<String, ChatMember>> memberInfo(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return {};
    final rows = await _db
        .from('profiles')
        .select('id, full_name, role')
        .inFilter('id', list);
    return {
      for (final r in rows)
        r['id'] as String: ChatMember(
          name: (r['full_name'] as String?) ?? '',
          role: UserRole.fromDb(r['role'] as String),
        ),
    };
  }
}
