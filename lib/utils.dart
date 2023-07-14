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
  if (name == "einsatz") {
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
