import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/default_shift_types.dart';
import 'package:himatch/models/shift_type.dart';

/// ユーザーが管理するシフト種別リスト。
/// デフォルト8種で初期化し、追加/編集/削除/並替えが可能。
final shiftTypesProvider =
    NotifierProvider<ShiftTypeNotifier, List<ShiftType>>(
  ShiftTypeNotifier.new,
);

class ShiftTypeNotifier extends Notifier<List<ShiftType>> {
  @override
  List<ShiftType> build() => List.of(defaultShiftTypes);

  void add(ShiftType shiftType) {
    state = [...state, shiftType];
  }

  void update(ShiftType updated) {
    state = [
      for (final st in state)
        if (st.id == updated.id) updated else st,
    ];
  }

  void remove(String id) {
    state = state.where((st) => st.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = List.of(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    // sortOrder を振り直す
    state = [
      for (var i = 0; i < list.length; i++)
        list[i].copyWith(sortOrder: i),
    ];
  }

  void resetToDefault() {
    state = List.of(defaultShiftTypes);
  }
}

/// shiftTypeId → ShiftType のルックアップマップ
final shiftTypeMapProvider = Provider<Map<String, ShiftType>>((ref) {
  final types = ref.watch(shiftTypesProvider);
  return {for (final st in types) st.id: st};
});

/// ShiftType の colorHex を Color に変換するヘルパー
Color shiftTypeColor(ShiftType shiftType) {
  return Color(int.parse(shiftType.colorHex, radix: 16));
}
