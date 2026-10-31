import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/models/chat_message.dart';
import '../../shared/repositories/message_repository.dart';
import '../auth/auth_controller.dart';

/// The way into the chat for a customer or a rider: a speech-bubble button for
/// the app bar, with a badge counting replies from the boutique not read yet.
class ChatButton extends StatefulWidget {
  const ChatButton({super.key, this.route = '/customer/chat'});

  /// Where the button leads: '/customer/chat' or '/rider/chat'.
  final String route;

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  Stream<List<ChatMessage>>? _stream;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthController>().profile;
    if (me != null) {
      _stream = context.read<MessageRepository>().watchThread(me.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _stream,
      builder: (context, snap) {
        final unread =
            (snap.data ?? const []).where((m) => m.fromAdmin && !m.isRead).length;
        return IconButton(
          tooltip: 'Message the boutique',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          onPressed: () => context.push(widget.route),
        );
      },
    );
  }
}
