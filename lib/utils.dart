import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:string_validator/string_validator.dart';

final values = [
  "Urlaub",
  "Krank",
  "Feiertag",
  "Üst-Abbau",
  "Fortbildung",
  "Supervision",
  "Dienstbesprechung",
  "Sonstiges"
];

String standardize(String name, String value) {
  value = value.trim();
  if (name == "einsatzstelle") {
    final v = value.toLowerCase();
    if (value.length >= 2) {
      for (final v2 in values) {
        if (v2.toLowerCase().startsWith(v)) {
          return v2;
        }
      }
    }
  } else if (name == "begin" || name == "end") {
    var col = value.indexOf(":");
    if (col == 0) {
      value = "00$value";
      col = 2;
    }
    if (col == 1) {
      value = "0$value";
      col = 2;
    }
    if (col > 2) {
      value = value.substring(0, 2) + value.substring(2);
      col = 2;
    }
    if (col == 2) {
      final subLen = value.substring(2).length;
      if (subLen == 1) {
        value = "${value}00";
      } else if (subLen == 2) {
        value = "${value}0";
      } else {
        value = value.substring(0, 5);
      }
    }

    col = value.indexOf(",");
    if (col == 0) {
      value = "00$value";
      col = 2;
    }
    if (col == 1) {
      value = "0$value";
      col = 2;
    }
    if (col > 2) {
      value = value.substring(0, 2) + value.substring(2);
      col = 2;
    }
    if (col > 0) {
      value = "${value.substring(0, 2)}:30";
    }

    if (col == -1) {
      if (value.length == 1) {
        value = "0$value:00";
      } else if (value.length == 2) {
        value = "$value:00";
      }
    }

    if (value.length != 5 ||
        value[2] != ":" ||
        !isNumeric(value.substring(0, 2)) ||
        !isNumeric(value.substring(3, 5))) {
      throw ("Uhrzeit hh:mm");
    } else {
      final h = int.parse(value.substring(0, 2));
      final m = int.parse(value.substring(3, 5));
      if (h > 23 || m > 59) {
        throw ("00:00-23:59");
      }
    }
  } else if (name == "fahrzeit") {
    if (!(value.isEmpty || value == "0,5")) {
      throw ("Fahrtzeit 0,5 oder nichts");
    }
    // } else if (name == "mvv") {
    // früher check auf kosten zwischen 5 und 15€
  } else {
    value = "Unknown name!?";
  }
  return value;
}

String date2Txt(DateTime date) {
  // Mo, DD.MM.YYYY
  final s = DateFormat("E, dd.MM.yyyy").format(date);
  return s
      .replaceFirst("Mon", "Mo")
      .replaceFirst("Tue", "Di")
      .replaceFirst("Wed", "Mi")
      .replaceFirst("Thu", "Do")
      .replaceFirst("Fri", "Fr")
      .replaceFirst("Sat", "Sa")
      .replaceFirst("Sun", "So");
}

String date2Idx(DateTime date) {
  return DateFormat("yyyy.MM.dd").format(date);
}

bool weekEnd(DateTime date) {
  final wd = date.weekday;
  return wd == DateTime.saturday || wd == DateTime.sunday;
}

int val2Int(String value) {
  return value == "true" || value == "1" ? 1 : 0;
}

final months = [
  "Dezember",
  "Januar",
  "Februar",
  "März",
  "April",
  "Mai",
  "Juni",
  "Juli",
  "August",
  "September",
  "Oktober",
  "November",
  "Dezember",
  "Januar",
];

// We want to be able to send the previous, current or next month.
// If today is the 31.08, and we want to send July,
// we must be able in the worst case to go back to 1.July, so ca.31+31 days.
const daysSpan = 65;

Future<List<int>?> selectMonthSearch(BuildContext ctx) async {
  final now = DateTime.now();
  final m = now.month;
  int y = now.year;

  int? monthNo = await showDialog<int>(
      context: ctx,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text("Welcher Monat?"),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m - 1),
              child: Text(months[m - 1]),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(months[m]),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m + 1),
              child: Text(months[m + 1]),
            ),
          ],
        );
      });
  if (monthNo == null) return null;
  if (monthNo == 0) {
    y--;
    monthNo = 12;
  }
  if (monthNo == 13) {
    y++;
    monthNo = 1;
  }
  return [y, monthNo];
}

int? deltaDays(String dayIdx) {
  // yes doing a simple sequential search...
  final now = DateTime.now();
  String nowIdx = date2Idx(now);
  if (dayIdx == nowIdx) {
    return 0;
  } else if (dayIdx.compareTo(nowIdx) < 0) {
    for (int i = 1; i < daysSpan; i++) {
      if (date2Idx(now.subtract(Duration(days: i))) == dayIdx) {
        return -i;
      }
    }
  } else {
    for (int i = 1; i < daysSpan; i++) {
      if (date2Idx(now.add(Duration(days: i))) == dayIdx) {
        return i;
      }
    }
  }
  return null;
}

bool isEmpty(Object? v) {
  if (v == null) return true;
  return (v as String) == "";
}
