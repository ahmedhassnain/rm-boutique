import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/chat_message.dart';
import '../../chat/chat_screen.dart';
import '../viewmodels/inbox_viewmodel.dart';
import 'widgets/filter_chips.dart';

/// OWNER: Ahmed (admin). The communication hub from the proposal: one inbox
/// of conversations with customers and riders, newest first. Customers tag
/// theirs "Browsing" or "Ready to order"; the Riders filter shows the delivery
/// riders. Tap one to read it and reply, with one-tap reply templates.
/// Messages arrive live.
class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InboxViewModel>();
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) {
      return Center(child: Text(vm.error!, textAlign: TextAlign.center));
    }

    final threads = vm.threads;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: FilterChips<InboxFilter>(
            options: InboxFilter.values,
            selected: vm.filter,
            labelOf: (f) => f.label,
            onSelected: vm.setFilter,
            twoColumns: true,
          ),
        ),
        Expanded(
          child: threads.isEmpty
              ? _Empty(filtered: vm.filter != InboxFilter.all)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ThreadCard(thread: threads[i]),
                ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.ink),
            const SizedBox(height: 16),
            Text(
              filtered ? 'Nothing here' : 'No messages yet',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'No conversation matches this filter.'
                  : 'When a customer or a rider writes from the app, the '
                      'conversation shows up here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread});
  final InboxThread thread;

  static final _time = DateFormat('h:mm a');
  static final _day = DateFormat('d MMM');

  String get _stamp {
    final t = thread.last.createdAt;
    final now = DateTime.now();
    final today = t.year == now.year && t.month == now.month && t.day == now.day;
    return today ? _time.format(t) : _day.format(t);
  }

  @override
  Widget build(BuildContext context) {
    final unread = thread.unread > 0;
    final last = thread.last;
    final preview = last.fromAdmin ? 'You: ${last.body}' : last.body;
    final initial =
        thread.name.isEmpty ? '?' : String.fromCharCode(thread.name.runes.first).toUpperCase();

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppSurface.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: AppSurface.card(),
      child: InkWell(
        onTap: () => context.push(
          '/admin/chat/${thread.memberId}',
          extra: ChatRouteArgs(name: thread.name, isRider: thread.isRider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tint,
                child: Text(initial,
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_stamp,
                            style: TextStyle(
                                fontSize: 11,
                                color: unread
                                    ? AppColors.ink
                                    : AppColors.muted,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? AppColors.slate : AppColors.muted,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (thread.isRider)
                          const _RoleChip('Rider')
                        else if (thread.tag != null)
                          _TagChip(thread.tag!),
                        const Spacer(),
                        if (unread)
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${thread.unread}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusDispatched.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.statusDispatched),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.tag);
  final MessageTag tag;

  @override
  Widget build(BuildContext context) {
    final ready = tag == MessageTag.readyToOrder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: ready ? AppColors.accent.withValues(alpha: 0.25) : AppColors.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag.label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
    );
  }
}
