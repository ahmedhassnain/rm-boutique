import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/chat_message.dart';
import '../../../shared/repositories/message_repository.dart';

/// Which conversations the Inbox shows.
enum InboxFilter {
  all('All'),
  browsing('Browsing'),
  readyToOrder('Ready to order'),
  riders('Riders');

  const InboxFilter(this.label);
  final String label;
}

/// One conversation (with a customer or a rider) as a row of the Inbox.
class InboxThread {
  const InboxThread({
    required this.memberId,
    required this.name,
    required this.last,
    required this.unread,
    required this.tag,
    required this.isRider,
  });

  final String memberId;
  final String name;
  final ChatMessage last; // newest message, for the preview and the time
  final int unread; // their messages the admin has not opened yet
  final MessageTag? tag; // what a customer said they were doing last
  final bool isRider; // a delivery rider rather than a customer
}

/// OWNER: Ahmed (admin). The communication hub: every conversation with a
/// customer or a rider, newest first, with Browsing / Ready to order / Riders
/// filters. Created once in the
/// admin home so the Inbox tab and its unread badge share one live stream.
class InboxViewModel extends ChangeNotifier {
  InboxViewModel(this._repo) {
    _sub = _repo.watchAll().listen(
      _onMessages,
      onError: (Object e) {
        error = 'Could not load the inbox.';
        loading = false;
        _notify();
      },
    );
  }

  final MessageRepository _repo;
  StreamSubscription<List<ChatMessage>>? _sub;
  bool _disposed = false;

  final Map<String, ChatMember> _members = {};
  final Set<String> _membersAsked = {};
  List<ChatMessage> _all = const [];

  bool loading = true;
  String? error;
  InboxFilter filter = InboxFilter.all;

  void setFilter(InboxFilter value) {
    filter = value;
    _notify();
  }

  void _onMessages(List<ChatMessage> list) {
    _all = list;
    loading = false;
    error = null;
    _notify();
    _loadMissingMembers();
  }

  Future<void> _loadMissingMembers() async {
    final missing = _all
        .map((m) => m.memberId)
        .where((id) => !_members.containsKey(id) && _membersAsked.add(id))
        .toList();
    if (missing.isEmpty) return;
    try {
      _members.addAll(await _repo.memberInfo(missing));
    } catch (_) {
      // Fall back to "Customer" in the list; try again on the next message.
      _membersAsked.removeAll(missing);
    }
    _notify();
  }

  /// Every conversation, newest first (before the filter).
  List<InboxThread> get allThreads {
    final byMember = <String, List<ChatMessage>>{};
    for (final m in _all) {
      byMember.putIfAbsent(m.memberId, () => []).add(m);
    }
    final threads = <InboxThread>[];
    for (final e in byMember.entries) {
      final msgs = e.value; // already oldest first
      final theirs = msgs.where((m) => !m.fromAdmin);
      final member = _members[e.key];
      final isRider = member?.isRider ?? false;
      final name = member?.name ?? '';
      threads.add(InboxThread(
        memberId: e.key,
        name: name.isEmpty ? (isRider ? 'Rider' : 'Customer') : name,
        last: msgs.last,
        unread: theirs.where((m) => !m.isRead).length,
        tag: theirs.isEmpty ? null : theirs.last.tag,
        isRider: isRider,
      ));
    }
    threads.sort((a, b) => b.last.createdAt.compareTo(a.last.createdAt));
    return threads;
  }

  /// The conversations the chosen filter lets through.
  List<InboxThread> get threads {
    final all = allThreads;
    return switch (filter) {
      InboxFilter.all => all,
      InboxFilter.browsing => all
          .where((t) => !t.isRider && t.tag == MessageTag.browsing)
          .toList(),
      InboxFilter.readyToOrder => all
          .where((t) => !t.isRider && t.tag == MessageTag.readyToOrder)
          .toList(),
      InboxFilter.riders => all.where((t) => t.isRider).toList(),
    };
  }

  /// Unread messages from customers and riders (the Inbox badge).
  int get unreadCount =>
      _all.where((m) => !m.fromAdmin && !m.isRead).length;

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
