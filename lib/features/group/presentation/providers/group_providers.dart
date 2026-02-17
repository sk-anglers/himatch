import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/demo_data.dart';
import 'package:himatch/models/group.dart';
import 'package:uuid/uuid.dart';

/// Local group state for offline-first development.
/// Will be replaced with Supabase-backed provider when connected.
final localGroupsProvider =
    NotifierProvider<LocalGroupsNotifier, List<Group>>(
  LocalGroupsNotifier.new,
);

/// Members per group (local state).
final localGroupMembersProvider =
    NotifierProvider<LocalGroupMembersNotifier, Map<String, List<GroupMember>>>(
  LocalGroupMembersNotifier.new,
);

class LocalGroupsNotifier extends Notifier<List<Group>> {
  static const _uuid = Uuid();
  static const _inviteChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  List<Group> build() => List.of(DemoData.groups);

  Group createGroup({
    required String name,
    String? description,
  }) {
    final group = Group(
      id: _uuid.v4(),
      name: name,
      description: description,
      inviteCode: _generateInviteCode(),
      createdBy: 'local-user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, group];

    // Add creator as owner
    ref.read(localGroupMembersProvider.notifier).addMember(
          groupId: group.id,
          role: 'owner',
        );

    return group;
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
    ref.read(localGroupMembersProvider.notifier).removeAllMembers(id);
  }

  Group? joinByInviteCode(String code) {
    final normalized = code.trim().toUpperCase();
    final index = state.indexWhere((g) => g.inviteCode == normalized);
    if (index == -1) return null;

    ref.read(localGroupMembersProvider.notifier).addMember(
          groupId: state[index].id,
          role: 'member',
        );
    return state[index];
  }

  void leaveGroup(String groupId) {
    ref.read(localGroupMembersProvider.notifier).removeMember(
          groupId: groupId,
          userId: 'local-user',
        );
    // If no members left, remove the group
    final members =
        ref.read(localGroupMembersProvider)[groupId] ?? [];
    if (members.isEmpty) {
      state = state.where((g) => g.id != groupId).toList();
    }
  }

  String _generateInviteCode() {
    final random = Random.secure();
    return List.generate(
      8,
      (_) => _inviteChars[random.nextInt(_inviteChars.length)],
    ).join();
  }
}

class LocalGroupMembersNotifier
    extends Notifier<Map<String, List<GroupMember>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<GroupMember>> build() => {
    for (final entry in DemoData.members.entries)
      entry.key: List.of(entry.value),
  };

  void addMember({
    required String groupId,
    String userId = 'local-user',
    String role = 'member',
    String? nickname,
  }) {
    final member = GroupMember(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      role: role,
      nickname: nickname,
      joinedAt: DateTime.now(),
    );
    final current = state[groupId] ?? [];
    state = {...state, groupId: [...current, member]};
  }

  void removeMember({required String groupId, required String userId}) {
    final current = state[groupId] ?? [];
    state = {
      ...state,
      groupId: current.where((m) => m.userId != userId).toList(),
    };
  }

  void removeAllMembers(String groupId) {
    final updated = Map<String, List<GroupMember>>.from(state);
    updated.remove(groupId);
    state = updated;
  }
}
