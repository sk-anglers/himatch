import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/services/supabase_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.watch(supabaseProvider));
});

final userGroupsProvider =
    FutureProvider.family<List<Group>, String>((ref, userId) async {
  final service = ref.watch(groupServiceProvider);
  return service.getGroupsByUser(userId);
});

class GroupService {
  final SupabaseClient _client;

  GroupService(this._client);

  Future<List<Group>> getGroupsByUser(String userId) async {
    final memberData = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    if (memberData.isEmpty) return [];

    final groupIds =
        memberData.map((m) => m['group_id'] as String).toList();

    final data = await _client
        .from('groups')
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    return data.map((json) => Group.fromJson(json)).toList();
  }

  Future<Group> createGroup({
    required String name,
    required String createdBy,
    String? description,
  }) async {
    final inviteCode = _generateInviteCode();

    final data = await _client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'invite_code': inviteCode,
          'created_by': createdBy,
        })
        .select()
        .single();

    final group = Group.fromJson(data);

    // Creator becomes owner
    await _client.from('group_members').insert({
      'group_id': group.id,
      'user_id': createdBy,
      'role': 'owner',
    });

    return group;
  }

  Future<Group> joinGroupByInviteCode(String inviteCode, String userId) async {
    final data = await _client
        .from('groups')
        .select()
        .eq('invite_code', inviteCode)
        .single();

    final group = Group.fromJson(data);

    await _client.from('group_members').insert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'member',
    });

    return group;
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final data = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .order('joined_at');

    return data.map((json) => GroupMember.fromJson(json)).toList();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
