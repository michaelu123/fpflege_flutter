import 'package:fpflege/db_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/utils.dart';

Future<String?> sendExcel(WidgetRef ref, int year, month) async {
  int m10 = month ~/ 10;
  int m1 = month % 10;
  final search = "$year.$m10$m1.__"; // where tag like 2023.06.__
  print("xxxx search $search");

  final data = await ref.read(dbProvider.notifier).loadMonthRaw(search);
  final dayIdx = checkComplete(data, year, month);
  return dayIdx;
}

String? checkComplete(List<Map<String, Object?>> data, int year, int month) {
  // data is sorted for day and fnr
  DateTime firstDay = DateTime(year, month, 1); // 2023.06.01
  String monthPrefix = date2Idx(firstDay).substring(0, 8); // 2023.06.
  int dataX = 0;
  Map<String, Object?> row;

  for (int i = 1; i <= 31; i++) {
    DateTime day = DateTime(year, month, i);
    String dayIdx = date2Idx(day); // 06.31 -> 07.01
    print("xxxx day $i $dayIdx ${day.weekday}");
    if (!dayIdx.startsWith(monthPrefix)) break; // iterated over whole month

    if (dataX >= data.length) {
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }
    }

    for (;;) {
      if (dataX >= data.length) {
        return dayIdx; // no data for this day
      }
      row = data[dataX];
      if (row["tag"] == null || row["fnr"] == null) {
        dataX++;
        continue;
      }
      break;
    }

    if (!(row["tag"]! as String).startsWith(dayIdx)) {
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }
      return dayIdx;
    }

    int nextFnr = 1;
    Map<String, Object?>? lastRow;
    while ((row["tag"]! as String).startsWith(dayIdx)) {
      if ((row["fnr"] as int) != nextFnr) return dayIdx;
      if (isEmpty(row["beginn"]) ||
          isEmpty(row["ende"]) ||
          (row["beginn"] as String).compareTo(row["ende"] as String) >= 0) {
        return dayIdx;
      }
      if (nextFnr > 1 &&
          (row["beginn"]! as String).compareTo(lastRow!["ende"] as String) <
              0) {
        return dayIdx;
      }
      nextFnr++;
      dataX++;
      if (dataX >= data.length) {
        break;
      }
      lastRow = row;
      row = data[dataX];
      if (row["tag"] == null || row["fnr"] == null) {
        continue;
      }
    }
  }
  return null;
}
