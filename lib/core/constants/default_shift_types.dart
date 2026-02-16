import 'package:himatch/models/shift_type.dart';

/// Himatchデフォルトの予定タイプ8種。
/// ターゲット: 大学生・友達グループ向け。
const defaultShiftTypes = [
  ShiftType(
    id: 'type-parttime',
    name: 'バイト',
    abbreviation: 'バ',
    colorHex: 'FFF39C12', // Orange
    sortOrder: 0,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-class',
    name: '授業',
    abbreviation: '授',
    colorHex: 'FF3498DB', // Blue
    sortOrder: 1,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-club',
    name: 'サークル',
    abbreviation: 'サ',
    colorHex: 'FF00B894', // Green
    sortOrder: 2,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-busy',
    name: '予定あり',
    abbreviation: '予',
    colorHex: 'FFE17055', // Coral
    sortOrder: 3,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-free-morning',
    name: '午前空き',
    abbreviation: '午前',
    colorHex: 'FF1ABC9C', // Teal
    startTime: '09:00',
    endTime: '12:00',
    isOff: true,
    sortOrder: 4,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-free-afternoon',
    name: '午後空き',
    abbreviation: '午後',
    colorHex: 'FF6C5CE7', // Purple (Himatch primary)
    startTime: '13:00',
    endTime: '18:00',
    isOff: true,
    sortOrder: 5,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-free-allday',
    name: '終日空き',
    abbreviation: '空',
    colorHex: 'FF27AE60', // Bright Green
    isOff: true,
    sortOrder: 6,
    isDefault: true,
  ),
  ShiftType(
    id: 'type-off',
    name: '休み',
    abbreviation: '休',
    colorHex: 'FFFF6B6B', // Pink
    isOff: true,
    sortOrder: 7,
    isDefault: true,
  ),
];
