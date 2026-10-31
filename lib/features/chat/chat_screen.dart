import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/repositories/message_repository.dart';
import 'chat_viewmodel.dart';

/// One-tap replies. Tapping one drops the text into the box so it can be
/// changed before sending. Each kind of person gets their own set.
const _adminToCustomer = <(String, String)>[
  (
    'Size and colour',
    'Thank you for your message! Which size and colour are you looking for? '
        'I will check the stock for you.'
  ),
  ('In stock', 'Good news, that piece is in stock and ready to be packed.'),
  (
    'Payment',
    'Your order is confirmed. Please upload your payment receipt under '
        'My orders so we can verify it.'
  ),
  (
    'On its way',
    'Your order is on its way with our rider. You will see the status update '
        'in the app.'
  ),
  ('Thank you', 'Thank you for shopping with R&M Boutique!'),
];

const _adminToRider = <(String, String)>[
  ('Ready for pickup', 'The next order is packed and ready for pickup at the boutique.'),
  ('Call the customer', 'Please call the customer before you arrive.'),
  ('Photo needed', 'Remember to take the delivery photo before marking it delivered.'),
  ('Thank you', 'Thank you, great work today!'),
];

const _riderToAdmin = <(String, String)>[
  ('At the boutique', 'I am at the boutique for the pickup.'),
  ('On my way', 'I am on my way to the customer now.'),
  ('Cannot reach customer', 'I cannot reach the customer. What should I do?'),
  ('Delivered', 'Delivered. The photo is uploaded.'),
];

/// Where the chat screens are opened from the Inbox: the person's name for the
/// title and whether they are a rider (different quick replies).
class ChatRouteArgs {
  const ChatRouteArgs({required this.name, this.isRider = false});
  final String name;
  final bool isRider;
}

/// The conversation between ONE person (a customer or a rider) and the
/// boutique. They open it as "Message the boutique"; the admin opens the same
/// conversation from the Inbox. Messages arrive live, and opening the screen
/// marks the other side's messages as read.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.memberId,
    required this.asAdmin,
    this.isRider = false,
    this.title = 'R&M Boutique',
  });

  final String memberId; // the customer or rider the conversation belongs to
  final bool asAdmin;
  final bool isRider; // the person is a rider (not a customer)
  final String title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ChatViewModel(
        c.read<MessageRepository>(),
        memberId: memberId,
        asAdmin: asAdmin,
        useTags: !isRider,
      ),
      child: _ChatView(title: title, asAdmin: asAdmin, isRider: isRider),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView(
      {required this.title, required this.asAdmin, required this.isRider});
  final String title;
  final bool asAdmin;
  final bool isRider;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final vm = context.read<ChatViewModel>();
    final ok = await vm.send(_text.text);
    if (ok && mounted) _text.clear();
  }

  /// Quick replies for this person, or null for a customer (who tags instead).
  List<(String, String)>? get _templates => widget.asAdmin
      ? (widget.isRider ? _adminToRider : _adminToCustomer)
      : (widget.isRider ? _riderToAdmin : null);

  void _useTemplate(String body) {
    _text.text = body;
    _text.selection = TextSelection.collapsed(offset: body.length);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(child: _messageList(vm)),
          if (vm.error != null && !vm.loading)
            Container(
              width: double.infinity,
              color: AppColors.alert.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(vm.error!,
                  style: const TextStyle(
                      color: AppColors.alert, fontWeight: FontWeight.w600)),
            ),
          _composer(vm),
        ],
      ),
    );
  }

  Widget _messageList(ChatViewModel vm) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 44, color: AppColors.ink),
              const SizedBox(height: 12),
              Text(
                widget.asAdmin
                    ? 'No messages yet'
                    : 'Ask us anything about sizes, stock or a custom order',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                widget.asAdmin
                    ? 'Write the first message below.'
                    : 'We reply right here in the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    // Newest at the bottom: the list is reversed so it stays pinned there.
    final items = vm.messages.reversed.toList();
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: items.length,
      itemBuilder: (context, i) => _Bubble(
        message: items[i],
        mine: vm.isMine(items[i]),
        showTag: widget.asAdmin,
      ),
    );
  }

  Widget _composer(ChatViewModel vm) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: AppSurface.shadowColor,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_templates != null)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in _templates!)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(t.$1),
                            onPressed: () => _useTemplate(t.$2),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final t in MessageTag.values)
                        ChoiceChip(
                          label: Text(t.label),
                          selected: vm.tag == t,
                          onSelected: (_) => vm.setTag(t),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.asAdmin
                            ? 'Reply to the customer'
                            : 'Write a message',
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: vm.sending ? null : _send,
                    icon: vm.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showTag,
  });

  final ChatMessage message;
  final bool mine;
  final bool showTag; // admin sees what the customer said they were doing

  static final _time = DateFormat('h:mm a');
  static final _dayTime = DateFormat('d MMM, h:mm a');

  String get _stamp {
    final t = message.createdAt;
    final now = DateTime.now();
    final today = t.year == now.year && t.month == now.month && t.day == now.day;
    return today ? _time.format(t) : _dayTime.format(t);
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final tagged = showTag && !mine && message.tag != null;
    const big = Radius.circular(18);
    const small = Radius.circular(5);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: mine ? AppColors.ink : Colors.white,
                  border:
                      mine ? null : Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.only(
                    topLeft: big,
                    topRight: big,
                    bottomLeft: mine ? big : small,
                    bottomRight: mine ? small : big,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tagged) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: message.tag == MessageTag.readyToOrder
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.tint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message.tag!.label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      message.body,
                      style: TextStyle(
                        color: mine ? Colors.white : AppColors.slate,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
                child: Text(
                  mine && message.isRead ? '$_stamp  ·  Seen' : _stamp,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
