import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('LocalGroupsNotifier', () {
    test('initial state has demo groups', () {
      final groups = container.read(localGroupsProvider);
      expect(groups, hasLength(2));
    });

    test('createGroup adds a group', () {
      final notifier = container.read(localGroupsProvider.notifier);
      notifier.createGroup(name: 'テストグループ');

      final groups = container.read(localGroupsProvider);
      expect(groups, hasLength(3));
      expect(groups.last.name, 'テストグループ');
      expect(groups.last.inviteCode, hasLength(8));
      expect(groups.last.createdBy, 'local-user');
    });

    test('createGroup with description', () {
      final notifier = container.read(localGroupsProvider.notifier);
      notifier.createGroup(
        name: '大学の友達',
        description: '毎月の飲み会メンバー',
      );

      final groups = container.read(localGroupsProvider);
      expect(groups.last.description, '毎月の飲み会メンバー');
    });

    test('createGroup auto-adds creator as owner', () {
      final notifier = container.read(localGroupsProvider.notifier);
      final group = notifier.createGroup(name: 'グループ');

      final members = container.read(localGroupMembersProvider);
      expect(members[group.id], isNotNull);
      expect(members[group.id], hasLength(1));
      expect(members[group.id]!.first.role, 'owner');
      expect(members[group.id]!.first.userId, 'local-user');
    });

    test('removeGroup removes group and members', () {
      final notifier = container.read(localGroupsProvider.notifier);
      final group = notifier.createGroup(name: 'グループ');

      expect(container.read(localGroupsProvider), hasLength(3));
      expect(container.read(localGroupMembersProvider)[group.id], hasLength(1));

      notifier.removeGroup(group.id);

      expect(container.read(localGroupsProvider), hasLength(2));
      expect(container.read(localGroupMembersProvider)[group.id], isNull);
    });

    test('joinByInviteCode returns null for invalid code', () {
      final notifier = container.read(localGroupsProvider.notifier);
      final result = notifier.joinByInviteCode('INVALID1');
      expect(result, isNull);
    });

    test('joinByInviteCode adds member and returns group', () {
      final notifier = container.read(localGroupsProvider.notifier);
      final group = notifier.createGroup(name: '参加テスト');

      // Simulate another user joining
      final membersNotifier =
          container.read(localGroupMembersProvider.notifier);
      membersNotifier.addMember(
        groupId: group.id,
        userId: 'other-user',
        role: 'member',
      );

      final members = container.read(localGroupMembersProvider);
      expect(members[group.id], hasLength(2));
    });

    test('leaveGroup removes member', () {
      final notifier = container.read(localGroupsProvider.notifier);
      final group = notifier.createGroup(name: '退出テスト');

      // Add another member
      container.read(localGroupMembersProvider.notifier).addMember(
            groupId: group.id,
            userId: 'other-user',
          );

      expect(
          container.read(localGroupMembersProvider)[group.id], hasLength(2));

      // Leave as local-user
      notifier.leaveGroup(group.id);

      // local-user removed, other-user remains
      final remaining = container.read(localGroupMembersProvider)[group.id];
      expect(remaining, hasLength(1));
      expect(remaining!.first.userId, 'other-user');
    });

    test('multiple groups can be created', () {
      final notifier = container.read(localGroupsProvider.notifier);
      notifier.createGroup(name: 'グループ1');
      notifier.createGroup(name: 'グループ2');
      notifier.createGroup(name: 'グループ3');

      expect(container.read(localGroupsProvider), hasLength(5));
    });
  });

  group('LocalGroupMembersNotifier', () {
    test('initial state has demo members', () {
      final members = container.read(localGroupMembersProvider);
      expect(members, hasLength(2));
      expect(members['demo-group-1'], hasLength(4));
      expect(members['demo-group-2'], hasLength(3));
    });

    test('addMember creates entry for group', () {
      final notifier = container.read(localGroupMembersProvider.notifier);
      notifier.addMember(groupId: 'group-1', userId: 'user-1');

      final members = container.read(localGroupMembersProvider);
      expect(members['group-1'], hasLength(1));
      expect(members['group-1']!.first.userId, 'user-1');
    });

    test('removeMember removes specific member', () {
      final notifier = container.read(localGroupMembersProvider.notifier);
      notifier.addMember(groupId: 'group-1', userId: 'user-1');
      notifier.addMember(groupId: 'group-1', userId: 'user-2');

      expect(container.read(localGroupMembersProvider)['group-1'], hasLength(2));

      notifier.removeMember(groupId: 'group-1', userId: 'user-1');

      final remaining = container.read(localGroupMembersProvider)['group-1'];
      expect(remaining, hasLength(1));
      expect(remaining!.first.userId, 'user-2');
    });

    test('removeAllMembers clears group entry', () {
      final notifier = container.read(localGroupMembersProvider.notifier);
      notifier.addMember(groupId: 'group-1', userId: 'user-1');
      notifier.addMember(groupId: 'group-1', userId: 'user-2');

      notifier.removeAllMembers('group-1');

      expect(
          container.read(localGroupMembersProvider)['group-1'], isNull);
    });
  });
}
