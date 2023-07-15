class FpflegeEinsatz {
  final String einsatzstelle;
  final String begin;
  final String end;
  final String fahrzeit;
  final bool kh;
  FpflegeEinsatz({
    required this.einsatzstelle,
    required this.begin,
    required this.end,
    required this.fahrzeit,
    required this.kh,
  });
  FpflegeEinsatz.empty()
      : einsatzstelle = "",
        begin = "",
        end = "",
        fahrzeit = "",
        kh = false;
}

class FpflegeDay {
  final String dayIdx;
  final FpflegeEinsatz fam1;
  final FpflegeEinsatz fam2;
  final FpflegeEinsatz fam3;
  FpflegeDay(this.dayIdx, this.fam1, this.fam2, this.fam3);
  FpflegeDay.empty(String dayIdxArg)
      : dayIdx = dayIdxArg,
        fam1 = FpflegeEinsatz.empty(),
        fam2 = FpflegeEinsatz.empty(),
        fam3 = FpflegeEinsatz.empty();

  // can this be improved? Dart has no object destructuring, as it seems.
  // using json as intermediate?
  FpflegeDay copyWith(int no, String name, String value) {
    var einsatzstelle = no == 1
        ? fam1.einsatzstelle
        : no == 2
            ? fam2.einsatzstelle
            : fam3.einsatzstelle;
    var begin = no == 1
        ? fam1.begin
        : no == 2
            ? fam2.begin
            : fam3.begin;
    var end = no == 1
        ? fam1.end
        : no == 2
            ? fam2.end
            : fam3.end;
    var fahrzeit = no == 1
        ? fam1.fahrzeit
        : no == 2
            ? fam2.fahrzeit
            : fam3.fahrzeit;
    var kh = no == 1
        ? fam1.kh
        : no == 2
            ? fam2.kh
            : fam3.kh;

    switch (name) {
      case "einsatzstelle":
        einsatzstelle = value;
        break;
      case "begin":
        begin = value;
        break;
      case "end":
        end = value;
        break;
      case "fahrzeit":
        fahrzeit = value;
        break;
      case "kh":
        kh = value == "true" || value == "1";
        break;
    }

    final fam = FpflegeEinsatz(
      einsatzstelle: einsatzstelle,
      begin: begin,
      end: end,
      fahrzeit: fahrzeit,
      kh: kh,
    );
    FpflegeDay d;
    switch (no) {
      case 1:
        d = FpflegeDay(dayIdx, fam, fam2, fam3);
        break;
      case 2:
        d = FpflegeDay(dayIdx, fam1, fam, fam3);
        break;
      case 3:
      default:
        d = FpflegeDay(dayIdx, fam1, fam2, fam);
        break;
    }
    return d;
  }
}
