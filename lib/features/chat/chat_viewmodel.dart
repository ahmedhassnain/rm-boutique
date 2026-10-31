import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/chat_message.dart';
import '../../shared/repositories/message_repository.dart';

/// One open conversation, for the customer's or rider's chat screen and for
/// the admin's reply screen. [asAdmin] decides which side we are on: it sets who the
/// messages are "from", which ones count as unread and whether a tag exists.
class ChatViewModel extends ChangeNotifier {
  ChatViewModel(this._repo,
      {required this.memberId, required this.asAdmin, this.useTags = true}) {
    _sub = _repo.watchThread(memberId).listen(
      _onMessages,
      onError: (Object e) {
        error = 'Could not load the conversation.';
        loading = false;
        _notify();
      },
    );
  }

  final MessageRepository _repo;
  final String memberId;
  final bool asAdmin;

  /// Customers tag each message (Browsing / Ready to order); riders do not.
  final bool useTags;

  StreamSubscription<List<ChatMessage>>? _sub;
  bool _disposed = false;
  bool _marking = false;

  List<ChatMessage> messages = const [];
  bool loading = true;
  bool sending = false;
  String? error;

  /// Customer only: what the next message is about.
  MessageTag tag = MessageTag.browsing;

  /// True for a message written by "me" (the side using this screen).
  bool isMine(ChatMessage m) => m.fromAdmin == asAdmin;

  void setTag(MessageTag value) {
    tag = value;
    _notify();
  }

  void _onMessages(List<ChatMessage> list) {
    messages = list;
    loading = false;
    error = null;
    _notify();
    // Looking at the conversation reads the other side's new messages.
    final hasUnread = list.any((m) => !isMine(m) && !m.isRead);
    if (hasUnread && !_marking) {
      _marking = true;
      unawaited(_markRead());
    }
  }

  Future<void> _markRead() async {
    try {
      await _repo.markRead(memberId);
    } catch (_) {
      // A missed read receipt is not worth bothering the person about.
    } finally {
      _marking = false;
    }
  }

  /// Sends [text]. Returns true when it went through, so the screen can
  /// clear the box; on failure [error] says what happened.
  Future<bool> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || sending) return false;
    sending = true;
    error = null;
    _notify();
    try {
      await _repo.send(
        memberId: memberId,
        body: body,
        fromAdmin: asAdmin,
        tag: (asAdmin || !useTags) ? null : tag,
      );
      return true;
    } catch (_) {
      error = 'Could not send. Check your connection and try again.';
      return false;
    } finally {
      sending = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
