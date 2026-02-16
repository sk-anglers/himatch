import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_pattern.freezed.dart';
part 'shift_pattern.g.dart';

@freezed
abstract class ShiftDefinition with _$ShiftDefinition {
  const factory ShiftDefinition({
    required String label,
    String? start,
    String? end,
    String? color,
  }) = _ShiftDefinition;

  factory ShiftDefinition.fromJson(Map<String, dynamic> json) =>
      _$ShiftDefinitionFromJson(json);
}

@freezed
abstract class ShiftPattern with _$ShiftPattern {
  const factory ShiftPattern({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    String? color,
    required List<ShiftDefinition> shifts,
    @JsonKey(name: 'rotation_days') int? rotationDays,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ShiftPattern;

  factory ShiftPattern.fromJson(Map<String, dynamic> json) =>
      _$ShiftPatternFromJson(json);
}
