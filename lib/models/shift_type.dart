import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_type.freezed.dart';
part 'shift_type.g.dart';

@freezed
abstract class ShiftType with _$ShiftType {
  const factory ShiftType({
    required String id,
    required String name,
    required String abbreviation,
    @JsonKey(name: 'color_hex') required String colorHex,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'is_off') @Default(false) bool isOff,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
  }) = _ShiftType;

  factory ShiftType.fromJson(Map<String, dynamic> json) =>
      _$ShiftTypeFromJson(json);
}
