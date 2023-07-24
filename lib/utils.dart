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

// einige Termine, von denen wir annehmen, daß sie sich nicht am nächsten Tag wiederholen:
final skipES = [
  // "krank",
  "feiertag",
  "üst-abbau",
  "fortbildung",
  "supervision",
  "dienstbesprechung",
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

DateTime idx2Date(String idx) {
  int y = int.parse(idx.substring(0, 4));
  int m = int.parse(idx.substring(5, 7));
  int d = int.parse(idx.substring(8, 10));
  return DateTime(y, m, d);
}

double sollStunden(int weekday, double modoStunden, double frStunden) {
  switch (weekday) {
    case DateTime.monday:
    case DateTime.tuesday:
    case DateTime.wednesday:
    case DateTime.thursday:
      return modoStunden;
    case DateTime.friday:
      return frStunden;
    default:
      return 0.0;
  }
}

bool weekEnd(DateTime date) {
  final wd = date.weekday;
  return wd == DateTime.saturday || wd == DateTime.sunday;
}

int val2Int(String value) {
  return value == "true" || value == "1" ? 1 : 0;
}

String? val2Str(String? value) {
  if (value == null || value == "") return null;
  return value;
}

String? val2Bool(Object? value) {
  if (value == null) return "";
  final v = value as int;
  return v != 0 ? "J" : "";
}

double diffHHMM(String b, String e) {
  //b, e = "hh:mm", e.g. b=08:30, e=11:00, bm=8*60+30m, em=11*60m,
  // em-bm= 2*60+30m = 2,5h
  int bm = int.parse(b.substring(0, 2)) * 60 + int.parse(b.substring(3, 5));
  int em = int.parse(e.substring(0, 2)) * 60 + int.parse(e.substring(3, 5));
  int diffm = em - bm;
  if (diffm > 360) diffm -= 30; // 30 min rest if >6h
  return (diffm ~/ 60) + (diffm % 60) / 60.0;
}

void addTime(Map<String, double> map, String key, double value) {
  double? o = map[key];
  if (o == null) {
    map[key] = value;
  } else {
    map[key] = o + value;
  }
}

void addDay(Map<String, Set<String>> map, String key, String value) {
  Set<String>? o = map[key];
  if (o == null) {
    o = <String>{};
    map[key] = o;
  }
  o.add(value);
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

String? checkStunden(String? value) {
  value = (value ?? "0,0").replaceFirst(",", ".");
  double? dv = double.tryParse(value);
  if (dv == null || dv < 4 || dv > 8) {
    return "Stunden zwischen 4 und 8";
  }

  // n or n,5, some checks already done in
  if (!value.contains(".")) {
    return null;
  }
  if (value.substring(2) != "5") {
    return "Auf halbe Stunden gerundet (z.B. 7,5)";
  }
  return null;
}
