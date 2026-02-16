import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/services/supabase_service.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(ref.watch(supabaseProvider));
});

final userSchedulesProvider =
    FutureProvider.family<List<Schedule>, String>((ref, userId) async {
  final service = ref.watch(scheduleServiceProvider);
  return service.getSchedulesByUser(userId);
});

class ScheduleService {
  final SupabaseClient _client;

  ScheduleService(this._client);

  Future<List<Schedule>> getSchedulesByUser(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client.from('schedules').select().eq('user_id', userId);

    if (from != null) {
      query = query.gte('start_time', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('end_time', to.toIso8601String());
    }

    final data = await query.order('start_time');
    return data.map((json) => Schedule.fromJson(json)).toList();
  }

  Future<Schedule> createSchedule(Schedule schedule) async {
    final data = await _client
        .from('schedules')
        .insert(schedule.toJson()..remove('id')..remove('created_at')..remove('updated_at'))
        .select()
        .single();
    return Schedule.fromJson(data);
  }

  Future<Schedule> updateSchedule(Schedule schedule) async {
    final data = await _client
        .from('schedules')
        .update(schedule.toJson()..remove('id')..remove('created_at')..remove('updated_at'))
        .eq('id', schedule.id)
        .select()
        .single();
    return Schedule.fromJson(data);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('schedules').delete().eq('id', scheduleId);
  }

  Stream<List<Schedule>> watchSchedulesByUser(String userId) {
    return _client
        .from('schedules')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('start_time')
        .map((data) => data.map((json) => Schedule.fromJson(json)).toList());
  }
}
