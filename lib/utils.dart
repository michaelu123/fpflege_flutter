import 'package:intl/intl.dart';

String standardize(String name, String value) {
  return "$value+";
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
