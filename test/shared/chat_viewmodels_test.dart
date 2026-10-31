import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/inbox_viewmodel.dart';
import 'package:rm_boutique/features/chat/chat_viewmodel.dart';
import 'package:rm_boutique/shared/models/chat_message.dart';
import 'package:rm_boutique/shared/models/profile.dart';

import '../admin/fakes.dart';

void main() {
  group('InboxViewModel', () {
    late FakeMessageRepository repo;

    setUp(() {
      repo = FakeMessageRepository()
        ..members = {
          'maheen': const ChatMember(name: 'Maheen Zubair', role: UserRole.customer),
          'sara': const ChatMember(name: 'Sara', role: UserRole.customer),
          'ahmad': const ChatMember(name: 'Ahmad Mousa', role: UserRole.rider),
        };
    });

    Future<InboxViewModel> start(List<ChatMessage> messages) async {
      final vm = InboxViewModel(repo);
      addTearDown(vm.dispose);
      repo.allStream.add(messages);
      await pumpEventQueue();
      return vm;
    }

    final t0 = DateTime(2026, 10, 31, 9);
    List<ChatMessage> sample() => [
          makeMessage(id: '1', memberId: 'maheen', body: 'Is M in stock?',
              tag: MessageTag.browsing, at: t0),
          makeMessage(id: '2', memberId: 'maheen', fromAdmin: true,
              body: 'Yes!', read: true, at: t0.add(const Duration(minutes: 5))),
          makeMessage(id: '3', memberId: 'maheen', body: 'I will order it',
              tag: MessageTag.readyToOrder,
              at: t0.add(const Duration(minutes: 10))),
          makeMessage(id: '4', memberId: 'sara', body: 'Hi',
              tag: MessageTag.browsing, read: true,
              at: t0.add(const Duration(minutes: 1))),
          makeMessage(id: '5', memberId: 'ahmad', body: 'At the boutique',
              at: t0.add(const Duration(minutes: 20))),
        ];

    test('groups messages into one row per person, newest first', () async {
      final vm = await start(sample());
      final threads = vm.threads;
      expect(threads.map((t) => t.name), ['Ahmad Mousa', 'Maheen Zubair', 'Sara']);
      expect(threads.first.last.body, 'At the boutique');
    });

    test('counts unread messages per row and in total', () async {
      final vm = await start(sample());
      final maheen = vm.threads.firstWhere((t) => t.memberId == 'maheen');
      expect(maheen.unread, 2); // messages 1 and 3 are unread
      expect(vm.unreadCount, 3); // Maheen 2 + Ahmad 1; Sara's is read
    });

    test('a thread takes the tag of the latest customer message', () async {
      final vm = await start(sample());
      final maheen = vm.threads.firstWhere((t) => t.memberId == 'maheen');
      expect(maheen.tag, MessageTag.readyToOrder);
    });

    test('filters: browsing, ready to order, riders', () async {
      final vm = await start(sample());
      vm.setFilter(InboxFilter.readyToOrder);
      expect(vm.threads.map((t) => t.memberId), ['maheen']);
      vm.setFilter(InboxFilter.browsing);
      expect(vm.threads.map((t) => t.memberId), ['sara']);
      vm.setFilter(InboxFilter.riders);
      expect(vm.threads.map((t) => t.memberId), ['ahmad']);
      expect(vm.threads.single.isRider, true);
      vm.setFilter(InboxFilter.all);
      expect(vm.threads.length, 3);
    });

    test('empty until the first message arrives', () async {
      final vm = await start(const []);
      expect(vm.loading, false);
      expect(vm.threads, isEmpty);
      expect(vm.unreadCount, 0);
    });
  });

  group('ChatViewModel', () {
    late FakeMessageRepository repo;
    setUp(() => repo = FakeMessageRepository());

    ChatViewModel make({bool asAdmin = false, bool useTags = true}) {
      final vm = ChatViewModel(repo,
          memberId: 'c1', asAdmin: asAdmin, useTags: useTags);
      addTearDown(vm.dispose);
      return vm;
    }

    test('shows the conversation and tells mine from theirs', () async {
      final vm = make();
      repo.threadStream.add([
        makeMessage(id: '1', body: 'Hi'),
        makeMessage(id: '2', fromAdmin: true, body: 'Hello!'),
      ]);
      await pumpEventQueue();
      expect(vm.loading, false);
      expect(vm.messages.length, 2);
      expect(vm.isMine(vm.messages[0]), true); // customer side: first is mine
      expect(vm.isMine(vm.messages[1]), false);
    });

    test('opening it marks the other side\'s messages as read, once', () async {
      make();
      repo.threadStream.add([makeMessage(id: '2', fromAdmin: true, body: 'Hello!')]);
      await pumpEventQueue();
      expect(repo.markedRead, ['c1']);
    });

    test('the admin side marks the customer\'s messages as read', () async {
      make(asAdmin: true);
      repo.threadStream.add([makeMessage(id: '1', body: 'Hi')]);
      await pumpEventQueue();
      expect(repo.markedRead, ['c1']);
    });

    test('a customer message carries the chosen tag', () async {
      final vm = make();
      vm.setTag(MessageTag.readyToOrder);
      expect(await vm.send('  I want the M  '), true);
      expect(repo.sent, ['false|ready_to_order|I want the M']);
    });

    test('a rider message has no tag', () async {
      final vm = make(useTags: false);
      expect(await vm.send('At the boutique'), true);
      expect(repo.sent, ['false|null|At the boutique']);
    });

    test('an admin reply is sent as the admin without a tag', () async {
      final vm = make(asAdmin: true);
      expect(await vm.send('Yes, in stock'), true);
      expect(repo.sent, ['true|null|Yes, in stock']);
    });

    test('an empty message is not sent', () async {
      final vm = make();
      expect(await vm.send('   '), false);
      expect(repo.sent, isEmpty);
    });

    test('a failed send shows an error and can be retried', () async {
      final vm = make();
      repo.sendError = Exception('offline');
      expect(await vm.send('Hello'), false);
      expect(vm.error, isNotNull);
      expect(vm.sending, false);
      repo.sendError = null;
      expect(await vm.send('Hello'), true);
      expect(vm.error, isNull);
    });
  });
}
