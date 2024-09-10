import 'dart:io';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fpflege/db_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart' as syspaths;

import 'package:fpflege/utils.dart';

Future<String?> sendExcel(
    WidgetRef ref, int year, month, List<Object> eigenschaften) async {
  int m10 = month ~/ 10;
  int m1 = month % 10;
  final search = "$year.$m10$m1.__"; // where tag like 2023.06.__

  final data = await ref.read(dbProvider.notifier).loadMonthRaw(search);
  final dayIdx = checkComplete(data, year, month);
  if (dayIdx != null) return dayIdx;
  final bytes = makeExcel(year, month, data, eigenschaften);
  final xlsx = await writeExcel(bytes, month, eigenschaften);

  if (Platform.isAndroid) {
    await sendEmail(
      month,
      eigenschaften[0] as String, // vorname
      eigenschaften[1] as String, // nachname
      eigenschaften[2] as String, // recipient
      xlsx, // xlsx file
    );
  }
  return null;
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
      if (isEmpty(row["einsatzstelle"]) ||
          isEmpty(row["beginn"]) ||
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

final spaltenNamen = [
  "Tag",
  "1.Einsatzstelle",
  "Beginn",
  "Ende",
  "KH",
  "Fahrt",
  "2.Einsatzstelle",
  "Beginn",
  "Ende",
  "KH",
  "Fahrt",
  "3.Einsatzstelle",
  "Beginn",
  "Ende",
  "KH",
  "Arbeitsstunden",
  "Sollstunden",
  "Überstunden",
];

final columnWidths = [
  17,
  30,
  8,
  8,
  3,
  8,
  30,
  8,
  8,
  3,
  8,
  30,
  8,
  8,
  3,
  10,
  10,
  10,
];

// Termine, bei denen Arbeitszeit und Sollzeit 0 sind
final nichtArbeit = ["urlaub", "krank", "feiertag", "üst-abbau"];

List<int> makeExcel(
  int year,
  int month,
  List<Map<String, Object?>> data,
  List<Object> eigenschaften,
) {
  final modoStunden =
      double.parse((eigenschaften[3] as String).replaceAll(",", "."));
  final frStunden =
      double.parse((eigenschaften[4] as String).replaceAll(",", "."));
  final sheetName = months[month];

  final wb = Workbook();
  final sheet = wb.worksheets[0];
  sheet.name = sheetName;
  sheet.getRangeByName("A2").freezePanes();
  //  sheet.getRangeByName('A1').columnWidth = 20;

  const hourFormat = "#,##0.00";
  int row = 1;
  int col = 1;
  for (final name in spaltenNamen) {
    sheet.getRangeByIndex(row, col).setText(name);
    sheet.getRangeByIndex(row, col).columnWidth =
        columnWidths[col - 1].toDouble();
    col++;
  }

  row = 2;
  double soll = 0, sumSoll = 0;
  double ist = 0, sumIst = 0;
  int wochenTage = 0; // Anzahl der Tage Mo-Fr
  Map<String, double> timePerEinsatz = {};
  Map<String, Set<String>> daysPerEinsatz = {};
  Set<String> arbeitsTage = {}; // an wievielen Tagen gearbeitet

  String lastDday = data[0]["tag"] as String;
  DateTime d = idx2Date(lastDday);
  soll = sollStunden(d.weekday, modoStunden, frStunden);
  if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
    wochenTage++;
  }

  for (final drow in data) {
    String dday = drow["tag"] as String;
    if (dday != lastDday) {
      d = idx2Date(dday);
      sheet.getRangeByIndex(row, 16).numberFormat = hourFormat;
      sheet.getRangeByIndex(row, 16).setNumber(ist);
      sheet.getRangeByIndex(row, 17).numberFormat = hourFormat;
      sheet.getRangeByIndex(row, 17).setNumber(soll);
      sheet.getRangeByIndex(row, 18).numberFormat = hourFormat;
      sheet.getRangeByIndex(row, 18).setNumber(ist - soll);
      row++;
      lastDday = dday;
      sumIst += ist;
      sumSoll += soll;
      ist = 0;
      soll = sollStunden(d.weekday, modoStunden, frStunden);
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        wochenTage++;
      }
    }
    sheet.getRangeByIndex(row, 1).setText(date2Txt(d));
    if ((drow["fnr"] as int) == 1) {
      col = 2;
    } else if ((drow["fnr"] as int) == 2) {
      col = 7;
    } else {
      col = 12;
    }
    final einsatzStelle = drow["einsatzstelle"] as String;
    final beginn = drow["beginn"] as String;
    final ende = drow["ende"] as String;
    sheet.getRangeByIndex(row, col).setText(einsatzStelle);
    sheet.getRangeByIndex(row, col + 1).setText(beginn);
    sheet.getRangeByIndex(row, col + 2).setText(ende);
    sheet.getRangeByIndex(row, col + 3).setText(val2Bool(drow["kh"]));

    if (col < 12) {
      String fahrtZeit = (drow["fahrtzeit"] ?? "0.0") as String;
      if (fahrtZeit.isEmpty) fahrtZeit = "0.0";
      fahrtZeit = fahrtZeit.replaceAll(",", ".");
      sheet.getRangeByIndex(row, col + 4).setNumber(double.parse(fahrtZeit));
      if (fahrtZeit != "0.0") {
        ist += 0.5;
        addTime(timePerEinsatz, "Fahrtzeit", 0.5);
        addDay(daysPerEinsatz, "Fahrtzeit", dday);
      }
    }

    final diffZeit = diffHHMM(beginn, ende);
    if (nichtArbeit.contains(einsatzStelle.toLowerCase())) {
      if (einsatzStelle.toLowerCase() != "üst-abbau") {
        soll -= diffZeit;
      }
    } else {
      ist += diffZeit;
      arbeitsTage.add(dday);
    }
    addTime(timePerEinsatz, einsatzStelle, diffZeit);
    addDay(daysPerEinsatz, einsatzStelle, dday);
  }
  sheet.getRangeByIndex(row, 16).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 16).setNumber(ist);
  sheet.getRangeByIndex(row, 17).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 17).setNumber(soll);
  sheet.getRangeByIndex(row, 18).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 18).setNumber(ist - soll);
  sumIst += ist;
  sumSoll += soll;

  int lrow = row;
  row += 2;
  sheet.getRangeByIndex(row, 1).setText("Formeln");
  sheet.getRangeByIndex(row, 16).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 16).setFormula("=SUM(P2:P$lrow)"); // 16=R
  sheet.getRangeByIndex(row, 17).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 17).setFormula("=SUM(Q2:Q$lrow)"); // 17=Q
  sheet.getRangeByIndex(row, 18).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 18).setFormula("=SUM(R2:R$lrow)"); // 18=R

  row++;
  sheet.getRangeByIndex(row, 1).setText("Summen");
  sheet.getRangeByIndex(row, 16).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 16).setNumber(sumIst); // 16=R
  sheet.getRangeByIndex(row, 17).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 17).setNumber(sumSoll); // 17=Q
  sheet.getRangeByIndex(row, 18).numberFormat = hourFormat;
  sheet.getRangeByIndex(row, 18).setNumber(sumIst - sumSoll); // 18=R

  row += 2;
  sheet.getRangeByIndex(row, 2).setText("Werktage");
  sheet.getRangeByIndex(row, 3).setNumber(wochenTage.toDouble());
  row += 1;
  sheet.getRangeByIndex(row, 2).setText("Arbeitstage");
  sheet.getRangeByIndex(row, 3).setNumber(arbeitsTage.length.toDouble());

  row += 2;
  sheet.getRangeByIndex(row, 2).setText("Einsatzstelle");
  sheet.getRangeByIndex(row, 3).setText("Tage");
  sheet.getRangeByIndex(row, 4).setText("Stunden");
  final list = timePerEinsatz.keys.toList();
  list.sort();
  for (final key in list) {
    row++;
    sheet.getRangeByIndex(row, 2).setText(key);
    sheet
        .getRangeByIndex(row, 3)
        .setNumber(daysPerEinsatz[key]!.length.toDouble());
    sheet.getRangeByIndex(row, 4).setNumber(timePerEinsatz[key]);
  }

  final bytes = wb.saveAsStream();
  wb.dispose();
  return bytes;
}

Future<File> writeExcel(
    List<int> bytes, int month, List<Object> eigenschaften) async {
  final monthName = months[month];
  final firstName = eigenschaften[0] as String;
  final lastName = eigenschaften[1] as String;
  if (Platform.isAndroid) {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    return await File("${appDir.path}/$monthName.$firstName.$lastName.xlsx")
        .writeAsBytes(bytes);
  } else {
    // Platform.isWindows
    return await File("$monthName.$firstName.$lastName.xlsx")
        .writeAsBytes(bytes);
  }
}

Future<void> sendEmail(
  int month,
  String vorname,
  String nachname,
  String emailadresse,
  File xlsx,
) async {
  final monthName = months[month];
  final Email email = Email(
    body:
        "Anbei das Arbeitsblatt von $vorname $nachname für den Monat $monthName.",
    subject: "Arbeitsblatt $monthName.$vorname.$nachname",
    recipients: [emailadresse],
    attachmentPaths: [xlsx.path],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
}
