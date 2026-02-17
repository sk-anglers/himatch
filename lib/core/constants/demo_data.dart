import 'package:himatch/core/constants/app_constants.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/models/schedule.dart';

/// デモモード用のシードデータ。
/// 起動直後からアプリの機能を体験できるようにする。
abstract class DemoData {
  // ─── グループ ───
  static const demoGroupId = 'demo-group-1';
  static const demoGroupId2 = 'demo-group-2';

  static final groups = [
    Group(
      id: demoGroupId,
      name: 'ゼミ3年',
      description: '田中ゼミ 3年メンバー',
      inviteCode: 'ZEMI2026',
      createdBy: AppConstants.localUserId,
      createdAt: DateTime(2026, 1, 15),
    ),
    Group(
      id: demoGroupId2,
      name: 'バイト仲間',
      description: 'カフェ☕ シフト共有用',
      inviteCode: 'CAFE2026',
      createdBy: 'demo-user-a',
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  // ─── メンバー ───
  static final members = <String, List<GroupMember>>{
    demoGroupId: [
      GroupMember(
        id: 'gm-1',
        groupId: demoGroupId,
        userId: AppConstants.localUserId,
        role: 'owner',
        joinedAt: DateTime(2026, 1, 15),
      ),
      GroupMember(
        id: 'gm-2',
        groupId: demoGroupId,
        userId: 'demo-user-a',
        role: 'member',
        nickname: 'あかり',
        joinedAt: DateTime(2026, 1, 16),
      ),
      GroupMember(
        id: 'gm-3',
        groupId: demoGroupId,
        userId: 'demo-user-b',
        role: 'member',
        nickname: 'けんた',
        joinedAt: DateTime(2026, 1, 16),
      ),
      GroupMember(
        id: 'gm-4',
        groupId: demoGroupId,
        userId: 'demo-user-c',
        role: 'member',
        nickname: 'みく',
        joinedAt: DateTime(2026, 1, 17),
      ),
    ],
    demoGroupId2: [
      GroupMember(
        id: 'gm-5',
        groupId: demoGroupId2,
        userId: 'demo-user-a',
        role: 'owner',
        nickname: 'あかり',
        joinedAt: DateTime(2026, 2, 1),
      ),
      GroupMember(
        id: 'gm-6',
        groupId: demoGroupId2,
        userId: AppConstants.localUserId,
        role: 'member',
        joinedAt: DateTime(2026, 2, 2),
      ),
      GroupMember(
        id: 'gm-7',
        groupId: demoGroupId2,
        userId: 'demo-user-d',
        role: 'member',
        nickname: 'そうた',
        joinedAt: DateTime(2026, 2, 3),
      ),
    ],
  };

  // ─── メンバーのスケジュール ───
  // userId → スケジュール一覧（リアルなバラつき）
  static Map<String, List<Schedule>> generateAllMemberSchedules() {
    final my = generateMySchedules();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return {
      AppConstants.localUserId: my,

      // あかり: 大学生。月水金は授業、火木はバイト
      'demo-user-a': [
        // 明日（+1）: 授業 9-15
        Schedule(
          id: 'demo-a-1', userId: 'demo-user-a', title: '授業',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 1, hours: 9)),
          endTime: today.add(const Duration(days: 1, hours: 15)),
          createdAt: today,
        ),
        // +2: 終日バイト
        Schedule(
          id: 'demo-a-2', userId: 'demo-user-a', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 2)),
          endTime: today.add(const Duration(days: 3)),
          isAllDay: true,
          createdAt: today,
        ),
        // +4: 授業 10-16
        Schedule(
          id: 'demo-a-4', userId: 'demo-user-a', title: '授業',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 4, hours: 10)),
          endTime: today.add(const Duration(days: 4, hours: 16)),
          createdAt: today,
        ),
        // +6: バイト 10-18
        Schedule(
          id: 'demo-a-6', userId: 'demo-user-a', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 6, hours: 10)),
          endTime: today.add(const Duration(days: 6, hours: 18)),
          createdAt: today,
        ),
        // +8: 授業 9-12
        Schedule(
          id: 'demo-a-8', userId: 'demo-user-a', title: '授業',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 8, hours: 9)),
          endTime: today.add(const Duration(days: 8, hours: 12)),
          createdAt: today,
        ),
        // +9: 終日予定
        Schedule(
          id: 'demo-a-9', userId: 'demo-user-a', title: '家族の予定',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 9)),
          endTime: today.add(const Duration(days: 10)),
          isAllDay: true,
          createdAt: today,
        ),
        // +11: バイト 17-22
        Schedule(
          id: 'demo-a-11', userId: 'demo-user-a', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 11, hours: 17)),
          endTime: today.add(const Duration(days: 11, hours: 22)),
          createdAt: today,
        ),
      ],

      // けんた: 社会人バイト多め。平日夕方以降は大体空き
      'demo-user-b': [
        // +1: バイト 9-17
        Schedule(
          id: 'demo-b-1', userId: 'demo-user-b', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 1, hours: 9)),
          endTime: today.add(const Duration(days: 1, hours: 17)),
          createdAt: today,
        ),
        // +3: バイト 9-17
        Schedule(
          id: 'demo-b-3', userId: 'demo-user-b', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 3, hours: 9)),
          endTime: today.add(const Duration(days: 3, hours: 17)),
          createdAt: today,
        ),
        // +5: 終日忙しい
        Schedule(
          id: 'demo-b-5', userId: 'demo-user-b', title: '引っ越し手伝い',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 5)),
          endTime: today.add(const Duration(days: 6)),
          isAllDay: true,
          createdAt: today,
        ),
        // +7: バイト 9-17
        Schedule(
          id: 'demo-b-7', userId: 'demo-user-b', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 7, hours: 9)),
          endTime: today.add(const Duration(days: 7, hours: 17)),
          createdAt: today,
        ),
        // +10: バイト 12-20
        Schedule(
          id: 'demo-b-10', userId: 'demo-user-b', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 10, hours: 12)),
          endTime: today.add(const Duration(days: 10, hours: 20)),
          createdAt: today,
        ),
        // +12: 終日予定
        Schedule(
          id: 'demo-b-12', userId: 'demo-user-b', title: '旅行',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 12)),
          endTime: today.add(const Duration(days: 13)),
          isAllDay: true,
          createdAt: today,
        ),
        // +13: 終日予定
        Schedule(
          id: 'demo-b-13', userId: 'demo-user-b', title: '旅行',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 13)),
          endTime: today.add(const Duration(days: 14)),
          isAllDay: true,
          createdAt: today,
        ),
      ],

      // みく: ゼミ3年のみ。授業多め
      'demo-user-c': [
        // +1: 授業 13-18
        Schedule(
          id: 'demo-c-1', userId: 'demo-user-c', title: 'ゼミ',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 1, hours: 13)),
          endTime: today.add(const Duration(days: 1, hours: 18)),
          createdAt: today,
        ),
        // +2: 授業 9-15
        Schedule(
          id: 'demo-c-2', userId: 'demo-user-c', title: '授業',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 2, hours: 9)),
          endTime: today.add(const Duration(days: 2, hours: 15)),
          createdAt: today,
        ),
        // +4: 終日予定
        Schedule(
          id: 'demo-c-4', userId: 'demo-user-c', title: '実家帰省',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 4)),
          endTime: today.add(const Duration(days: 5)),
          isAllDay: true,
          createdAt: today,
        ),
        // +7: 授業 9-12
        Schedule(
          id: 'demo-c-7', userId: 'demo-user-c', title: '授業',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 7, hours: 9)),
          endTime: today.add(const Duration(days: 7, hours: 12)),
          createdAt: today,
        ),
        // +8: ゼミ 13-17
        Schedule(
          id: 'demo-c-8', userId: 'demo-user-c', title: 'ゼミ',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 8, hours: 13)),
          endTime: today.add(const Duration(days: 8, hours: 17)),
          createdAt: today,
        ),
        // +11: 終日バイト
        Schedule(
          id: 'demo-c-11', userId: 'demo-user-c', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 11)),
          endTime: today.add(const Duration(days: 12)),
          isAllDay: true,
          createdAt: today,
        ),
      ],

      // そうた: バイト仲間のみ。週3-4でバイト
      'demo-user-d': [
        // +1: バイト 17-22
        Schedule(
          id: 'demo-d-1', userId: 'demo-user-d', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 1, hours: 17)),
          endTime: today.add(const Duration(days: 1, hours: 22)),
          createdAt: today,
        ),
        // +3: バイト 17-22
        Schedule(
          id: 'demo-d-3', userId: 'demo-user-d', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 3, hours: 17)),
          endTime: today.add(const Duration(days: 3, hours: 22)),
          createdAt: today,
        ),
        // +4: バイト 17-22
        Schedule(
          id: 'demo-d-4', userId: 'demo-user-d', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 4, hours: 17)),
          endTime: today.add(const Duration(days: 4, hours: 22)),
          createdAt: today,
        ),
        // +6: 終日予定
        Schedule(
          id: 'demo-d-6', userId: 'demo-user-d', title: '彼女とデート',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 6)),
          endTime: today.add(const Duration(days: 7)),
          isAllDay: true,
          createdAt: today,
        ),
        // +8: バイト 17-22
        Schedule(
          id: 'demo-d-8', userId: 'demo-user-d', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 8, hours: 17)),
          endTime: today.add(const Duration(days: 8, hours: 22)),
          createdAt: today,
        ),
        // +10: バイト 10-18
        Schedule(
          id: 'demo-d-10', userId: 'demo-user-d', title: 'バイト',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 10, hours: 10)),
          endTime: today.add(const Duration(days: 10, hours: 18)),
          createdAt: today,
        ),
        // +12: 終日予定
        Schedule(
          id: 'demo-d-12', userId: 'demo-user-d', title: 'テスト勉強',
          scheduleType: ScheduleType.event,
          startTime: today.add(const Duration(days: 12)),
          endTime: today.add(const Duration(days: 13)),
          isAllDay: true,
          createdAt: today,
        ),
      ],
    };
  }

  // ─── 自分のスケジュール ───
  static List<Schedule> generateMySchedules() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      // 今日: バイト
      Schedule(
        id: 'demo-my-0',
        userId: AppConstants.localUserId,
        title: 'バイト',
        scheduleType: ScheduleType.shift,
        startTime: today,
        endTime: today.add(const Duration(days: 1)),
        isAllDay: true,
        shiftTypeId: 'type-parttime',
        color: 'FFF39C12',
        createdAt: today,
      ),
      // 明日: 授業
      Schedule(
        id: 'demo-my-1',
        userId: AppConstants.localUserId,
        title: '授業',
        scheduleType: ScheduleType.shift,
        startTime: today.add(const Duration(days: 1)),
        endTime: today.add(const Duration(days: 2)),
        isAllDay: true,
        shiftTypeId: 'type-class',
        color: 'FF3498DB',
        createdAt: today,
      ),
      // 明後日: 終日空き
      Schedule(
        id: 'demo-my-2',
        userId: AppConstants.localUserId,
        title: '終日空き',
        scheduleType: ScheduleType.free,
        startTime: today.add(const Duration(days: 2)),
        endTime: today.add(const Duration(days: 3)),
        isAllDay: true,
        shiftTypeId: 'type-free-allday',
        color: 'FF27AE60',
        createdAt: today,
      ),
      // 3日後: サークル
      Schedule(
        id: 'demo-my-3',
        userId: AppConstants.localUserId,
        title: 'サークル',
        scheduleType: ScheduleType.shift,
        startTime: today.add(const Duration(days: 3, hours: 15)),
        endTime: today.add(const Duration(days: 3, hours: 18)),
        shiftTypeId: 'type-club',
        color: 'FF00B894',
        createdAt: today,
      ),
      // 5日後: 午後空き
      Schedule(
        id: 'demo-my-5',
        userId: AppConstants.localUserId,
        title: '午後空き',
        scheduleType: ScheduleType.free,
        startTime: today.add(const Duration(days: 5, hours: 13)),
        endTime: today.add(const Duration(days: 5, hours: 18)),
        shiftTypeId: 'type-free-afternoon',
        color: 'FF6C5CE7',
        createdAt: today,
      ),
      // 6日後: 休み
      Schedule(
        id: 'demo-my-6',
        userId: AppConstants.localUserId,
        title: '休み',
        scheduleType: ScheduleType.free,
        startTime: today.add(const Duration(days: 6)),
        endTime: today.add(const Duration(days: 7)),
        isAllDay: true,
        shiftTypeId: 'type-off',
        color: 'FFFF6B6B',
        createdAt: today,
      ),
      // 7日後: 一般予定（シフトなし）
      Schedule(
        id: 'demo-my-7',
        userId: AppConstants.localUserId,
        title: '歯医者',
        scheduleType: ScheduleType.event,
        startTime: today.add(const Duration(days: 7, hours: 10)),
        endTime: today.add(const Duration(days: 7, hours: 11)),
        createdAt: today,
      ),
      // 8日後: バイト
      Schedule(
        id: 'demo-my-8',
        userId: AppConstants.localUserId,
        title: 'バイト',
        scheduleType: ScheduleType.shift,
        startTime: today.add(const Duration(days: 8)),
        endTime: today.add(const Duration(days: 9)),
        isAllDay: true,
        shiftTypeId: 'type-parttime',
        color: 'FFF39C12',
        createdAt: today,
      ),
      // 10日後: 午前空き
      Schedule(
        id: 'demo-my-10',
        userId: AppConstants.localUserId,
        title: '午前空き',
        scheduleType: ScheduleType.free,
        startTime: today.add(const Duration(days: 10, hours: 9)),
        endTime: today.add(const Duration(days: 10, hours: 12)),
        shiftTypeId: 'type-free-morning',
        color: 'FF1ABC9C',
        createdAt: today,
      ),
    ];
  }
}
