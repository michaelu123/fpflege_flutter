import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/day.dart';
import 'package:fpflege/utils.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
// import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

Future<Database> _getDatabase() async {
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, "arbeitsblatt.db"),
    onCreate: (db, version) async {
      await db.execute("""
          CREATE TABLE arbeitsblatt(
            tag TEXT,fnr INTEGER,
            einsatzstelle TEXT,beginn TEXT,ende TEXT,
            fahrtzeit TEXT,kh INTEGER)
      """);
      await db.execute("""
          CREATE UNIQUE INDEX tagfnr on arbeitsblatt(tag,fnr)
      """);
      await db.execute("""
          CREATE TABLE eigenschaften(
            vorname TEXT,
            nachname TEXT,
            modostunden TEXT,
            frstunden TEXT,
            emailadresse TEXT)
      """);
    },
    version: 1,
  );
  return db;
}

final fieldNameMap = {
  "einsatzstelle": "einsatzstelle",
  "begin": "beginn",
  "end": "ende",
  "fahrzeit": "fahrtzeit",
  "kh": "kh",
};

class DBNotifier extends StateNotifier<FpflegeDay> {
  DBNotifier() : super(FpflegeDay.empty(""));
  Database? db;

  Future<FpflegeDay> loadDay(DateTime date) async {
    String dayIdx = date2Idx(date); // YYYY.MM.DD

    db ??= await _getDatabase();
    final data = await db!.query(
      "arbeitsblatt",
      where: "tag = ?",
      whereArgs: [dayIdx],
    );

    var dayRes = FpflegeDay.empty(dayIdx);

    // if (data.isEmpty) {
    //   // for testing
    //   String dy = date2Txt(date);
    //   await db!.insert("arbeitsblatt", {
    //     "tag": dayIdx,
    //     "fnr": 3,
    //     "einsatzstelle": dy,
    //   });
    //   dayRes = dayRes.copyWith(3, "einsatzstelle", dy);
    // }

    for (final row in data) {
      final noVal = row["fnr"];
      if (noVal == null) continue;
      int no = noVal as int;
      final einsatzstelle = row["einsatzstelle"];
      if (einsatzstelle != null) {
        dayRes = dayRes.copyWith(no, "einsatzstelle", einsatzstelle as String);
      }
      final begin = row["beginn"];
      if (begin != null) {
        dayRes = dayRes.copyWith(no, "begin", begin as String);
      }
      final end = row["ende"];
      if (end != null) {
        dayRes = dayRes.copyWith(no, "end", end as String);
      }
      final fahrzeit = row["fahrtzeit"];
      if (fahrzeit != null) {
        dayRes = dayRes.copyWith(no, "fahrzeit", fahrzeit as String);
      }
      final kh = row["kh"];
      if (kh != null) {
        dayRes = dayRes.copyWith(no, "kh", kh.toString());
      }
    }
    return dayRes;
  }

  Future<void> load(DateTime date) async {
    var day = await loadDay(date);

    if (day.isEmpty && !weekEnd(date)) {
      for (int i = 1; i < 5; i++) {
        final prevDate = date.subtract(Duration(days: i));
        final prevDay = await loadDay(prevDate);
        final prevEinsatz = prevDay.fam1.einsatzstelle;

        if (prevEinsatz != "" && !skipES.contains(prevEinsatz.toLowerCase())) {
          String dayIdx = date2Idx(date);
          day = FpflegeDay(dayIdx, prevDay.fam1, prevDay.fam2, prevDay.fam3);
          await storeDay(day);
          break;
        }
      }
    }
    state = day;
  }

  Future<void> store(int no, String name, String value) async {
    state = state.copyWith(no, name, value);
    db ??= await _getDatabase();
    int chgCnt = await db!.update(
      "arbeitsblatt",
      {fieldNameMap[name]!: name == "kh" ? val2Int(value) : val2Str(value)},
      where: "tag=? and fnr=?",
      whereArgs: [state.dayIdx, no],
    );
    if (chgCnt == 0 && value != "") {
      await db!.insert("arbeitsblatt", {
        "tag": state.dayIdx,
        "fnr": no,
        fieldNameMap[name]!: name == "kh" ? val2Int(value) : val2Str(value),
      });
    }
  }

  Future<void> storeDay(FpflegeDay day) async {
    await storeEinsatz(day.dayIdx, 1, day.fam1);
    await storeEinsatz(day.dayIdx, 2, day.fam2);
    await storeEinsatz(day.dayIdx, 3, day.fam3);
  }

  Future<void> storeEinsatz(
      String dayIdx, int no, FpflegeEinsatz einsatz) async {
    if (einsatz.einsatzstelle == "") return;
    db ??= await _getDatabase();
    await db!.insert("arbeitsblatt", {
      "tag": dayIdx,
      "fnr": no,
      "einsatzstelle": einsatz.einsatzstelle,
      "beginn": einsatz.begin,
      "ende": einsatz.end,
      "fahrtzeit": einsatz.fahrzeit,
      "kh": einsatz.kh ? 1 : 0,
    });
  }

  Future<void> clearAll() async {
    db ??= await _getDatabase();
    await db!.delete(
      "arbeitsblatt",
      where: "tag = ?",
      whereArgs: [state.dayIdx],
    );
    state = FpflegeDay.empty(state.dayIdx);
  }

  Future<List<Map<String, Object?>>> loadMonthRaw(String monthSearch) async {
    db ??= await _getDatabase();
    await db!.delete(
      "arbeitsblatt",
      where: "einsatzstelle is null and beginn is null and ende is null",
    );
    final data = await db!.query(
      "arbeitsblatt",
      where: "tag like ?",
      whereArgs: [monthSearch],
      orderBy: "tag,fnr",
    );
    return data;
  }

  Future<List<Object>> readEigenschaften() async {
    db ??= await _getDatabase();
    final data = await db!.query(
      "eigenschaften",
    );
    if (data.isEmpty) {
      return ["", "", "", "", ""];
    }
    final vorname = data[0]["vorname"] as String;
    final nachname = data[0]["nachname"] as String;
    final email = data[0]["emailadresse"] as String;
    final modoStunden = data[0]["modostunden"] as String;
    final frStunden = data[0]["frstunden"] as String;

    return [vorname, nachname, email, modoStunden, frStunden];
  }

  Future<void> storeEigenschaften(String vorname, String nachname, String email,
      String modoStunden, String frStunden) async {
    db ??= await _getDatabase();
    await db!.delete("eigenschaften");
    await db!.insert("eigenschaften", {
      "vorname": vorname,
      "nachname": nachname,
      "emailadresse": email,
      "modostunden": modoStunden,
      "frstunden": frStunden,
    });
  }
}

final dbProvider = StateNotifierProvider<DBNotifier, FpflegeDay>((ref) {
  return DBNotifier();
});
