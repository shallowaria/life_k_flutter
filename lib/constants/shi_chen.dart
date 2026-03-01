/// ShiChen (时辰) constants - Chinese traditional 12 double-hours
class ShiChen {
  final String name;
  final String displayName;
  final String range;
  final int startHour;
  final int endHour;
  final int midHour;

  const ShiChen({
    required this.name,
    required this.displayName,
    required this.range,
    required this.startHour,
    required this.endHour,
    required this.midHour,
  });
}

const List<ShiChen> shiChenList = [
  ShiChen(
    name: '子时',
    displayName: '子时（夜半）',
    range: '23:00-01:00',
    startHour: 23,
    endHour: 1,
    midHour: 0,
  ),
  ShiChen(
    name: '丑时',
    displayName: '丑时（鸡鸣）',
    range: '01:00-03:00',
    startHour: 1,
    endHour: 3,
    midHour: 2,
  ),
  ShiChen(
    name: '寅时',
    displayName: '寅时（平旦）',
    range: '03:00-05:00',
    startHour: 3,
    endHour: 5,
    midHour: 4,
  ),
  ShiChen(
    name: '卯时',
    displayName: '卯时（日出）',
    range: '05:00-07:00',
    startHour: 5,
    endHour: 7,
    midHour: 6,
  ),
  ShiChen(
    name: '辰时',
    displayName: '辰时（食时）',
    range: '07:00-09:00',
    startHour: 7,
    endHour: 9,
    midHour: 8,
  ),
  ShiChen(
    name: '巳时',
    displayName: '巳时（隅中）',
    range: '09:00-11:00',
    startHour: 9,
    endHour: 11,
    midHour: 10,
  ),
  ShiChen(
    name: '午时',
    displayName: '午时（日中）',
    range: '11:00-13:00',
    startHour: 11,
    endHour: 13,
    midHour: 12,
  ),
  ShiChen(
    name: '未时',
    displayName: '未时（日昳）',
    range: '13:00-15:00',
    startHour: 13,
    endHour: 15,
    midHour: 14,
  ),
  ShiChen(
    name: '申时',
    displayName: '申时（哺时）',
    range: '15:00-17:00',
    startHour: 15,
    endHour: 17,
    midHour: 16,
  ),
  ShiChen(
    name: '酉时',
    displayName: '酉时（日入）',
    range: '17:00-19:00',
    startHour: 17,
    endHour: 19,
    midHour: 18,
  ),
  ShiChen(
    name: '戌时',
    displayName: '戌时（黄昏）',
    range: '19:00-21:00',
    startHour: 19,
    endHour: 21,
    midHour: 20,
  ),
  ShiChen(
    name: '亥时',
    displayName: '亥时（人定）',
    range: '21:00-23:00',
    startHour: 21,
    endHour: 23,
    midHour: 22,
  ),
];

/// Get hour from ShiChen name
int getHourFromShiChen(String shiChenName) {
  final sc = shiChenList.firstWhere(
    (s) => s.name == shiChenName,
    orElse: () => throw ArgumentError('Invalid shi chen name: $shiChenName'),
  );
  return sc.midHour;
}

/// Get ShiChen name from hour (0–23).
///
/// 子时跨越午夜（23:00–01:00）：hour 23 和 hour 0 归子时，hour 1（01:00）归丑时。
/// 传入 0–23 范围外的值将抛出 [ArgumentError]。
String getShiChenFromHour(int hour) {
  if (hour < 0 || hour > 23) {
    throw ArgumentError('无效时辰小时值：$hour，需在 0–23 范围内');
  }
  // 子时横跨午夜：23:00–00:59 → 子时；01:00 起归丑时
  if (hour == 23 || hour == 0) return '子时';
  return shiChenList
      .where((s) => s.name != '子时')
      .firstWhere(
        (s) => hour >= s.startHour && hour < s.endHour,
        orElse: () => throw ArgumentError('无法匹配时辰，hour=$hour'),
      )
      .name;
}
