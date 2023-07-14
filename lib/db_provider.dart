import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/day.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
// import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _getDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
          CREATE TABLE eigenschaften(
            vorname TEXT,
            nachname TEXT,
            wochenstunden TEXT,
            emailadresse TEXT)
      """);
    },
    version: 1,
  );
  return db;
}

final fieldNameMap = {
  "einsatz": "einsatzstelle",
  "begin": "beginn",
  "end": "ende",
  "fahrzeit": "fahrtzeit",
  "kh": "kh",
};

class DBNotifier extends StateNotifier<FpflegeDay> {
  DBNotifier() : super(FpflegeDay.empty(""));
  Database? db;

  Future<FpflegeDay> loadDay(String dayIdx) async {
    db ??= await _getDatabase();
    final data = await db!.query(
      "arbeitsblatt",
      where: "tag = ?",
      whereArgs: [dayIdx],
    );

    var day = FpflegeDay.empty(dayIdx);
    for (final row in data) {
      final noVal = row["fnr"];
      if (noVal == null) continue;
      int no = noVal as int;
      final einsatz = row["einsatzstelle"];
      if (einsatz != null) day = day.copyWith(no, "einsatz", einsatz as String);
      final begin = row["beginn"];
      if (begin != null) day = day.copyWith(no, "begin", begin as String);
      final end = row["end"];
      if (end != null) day = day.copyWith(no, "end", end as String);
      final fahrzeit = row["fahrtzeit"];
      if (fahrzeit != null) {
        day = day.copyWith(no, "fahrzeit", fahrzeit as String);
      }
      final kh = row["kh"];
      if (kh != null) day = day.copyWith(no, "kh", kh as String);
    }
    return day;
  }

  Future<void> load(String dayIdx) async {
    state = await loadDay(dayIdx);
  }

  Future<void> store(int no, String name, String value) async {
    state = state.copyWith(no, name, value);
    db ??= await _getDatabase();
    int chgCnt = await db!.update(
      "arbeitsblatt",
      {fieldNameMap[name]!: value},
      where: "tag=? and fnr=?",
      whereArgs: [state.dayIdx, no],
    );
    if (chgCnt == 0) {
      await db!.insert("arbeitsblatt", {
        "tag": state.dayIdx,
        "fnr": no,
        fieldNameMap[name]!: value,
      });
    }
  }

  Future<List<Object>> readEigenschaften() async {
    db ??= await _getDatabase();
    final data = await db!.query(
      "eigenschaften",
    );
    if (data.isEmpty) {
      return ["", "", "", 30];
    }
    final vorname = data[0]["vorname"] as String;
    final nachname = data[0]["nachname"] as String;
    final email = data[0]["emailadresse"] as String;
    final stunden = data[0]["wochenstunden"] as int;

    return [vorname, nachname, email, stunden];
  }

  Future<void> storeEigenschaften(
      String vorname, String nachname, String email, int stunden) async {
    db ??= await _getDatabase();
    await db!.insert("eigenschaften", {
      "vorname": vorname,
      "nachname": nachname,
      "emailadresse": email,
      "wochenstunden": stunden,
    });
  }
}

final dbProvider = StateNotifierProvider<DBNotifier, FpflegeDay>((ref) {
  return DBNotifier();
});
