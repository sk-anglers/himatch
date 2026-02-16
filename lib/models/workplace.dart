import 'package:freezed_annotation/freezed_annotation.dart';

part 'workplace.freezed.dart';
part 'workplace.g.dart';

@freezed
abstract class Workplace with _$Workplace {
  const factory Workplace({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'hourly_wage') required int hourlyWage,
    @JsonKey(name: 'closing_day') @Default(25) int closingDay,
    @JsonKey(name: 'overtime_multiplier') @Default(1.25) double overtimeMultiplier,
    @JsonKey(name: 'night_multiplier') @Default(1.25) double nightMultiplier,
    @JsonKey(name: 'holiday_multiplier') @Default(1.35) double holidayMultiplier,
    @JsonKey(name: 'transport_cost') @Default(0) int transportCost,
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Workplace;

  factory Workplace.fromJson(Map<String, dynamic> json) =>
      _$WorkplaceFromJson(json);
}
