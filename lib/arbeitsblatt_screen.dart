import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/db_provider.dart';
import 'package:fpflege/eigenschaften_screen.dart';
import 'package:fpflege/einsatz.dart';
import 'package:fpflege/send_excel.dart';
import 'package:fpflege/utils.dart';

class Arbeitsblatt extends ConsumerStatefulWidget {
  const Arbeitsblatt({super.key});

  @override
  ConsumerState<Arbeitsblatt> createState() => _ArbeitsblattState();
}

const int tODAY = 999; // need a special value for "today"

class _ArbeitsblattState extends ConsumerState<Arbeitsblatt> {
  var date = DateTime.now();
  late Future<void> Function(int, String, String) store;
  late Future<void> dayFuture;
  late Future<List<Object>> eigFuture;
  late Future initFuture;
  List<Object>? eigenschaften;
  late PageController pageController;
  int currDay = daysSpan;

  // in PageView.onPageChanged we must know
  // if we changed the page via the controller (explicitChange=true)
  // or by swiping (explicitChange=false)
  bool explicitChange = false;

  @override
  void initState() {
    super.initState();
    dayFuture = ref.read(dbProvider.notifier).load(date);
    eigFuture = ref.read(dbProvider.notifier).readEigenschaften();
    initFuture = Future.wait([dayFuture, eigFuture]);
    store = ref.read(dbProvider.notifier).store;
    // day daysSpan = today,
    pageController = PageController(initialPage: daysSpan);
  }

  Future<void> useDate(int days) async {
    explicitChange = true;
    if (days == tODAY) {
      currDay = daysSpan;
      days = 0;
    }
    currDay += days;
    if (currDay < 0) {
      currDay = 0;
    } else if (currDay >= 2 * daysSpan) {
      currDay = 2 * daysSpan - 1;
    }
    //print("xxxx useDate $days $currDay");
    await pageController.animateToPage(currDay,
        duration: const Duration(milliseconds: 500), curve: Curves.linear);
    final now = DateTime.now();
    date = now.add(Duration(days: currDay - daysSpan));
    await ref.read(dbProvider.notifier).load(date);
    setState(() {});
    explicitChange = false;
  }

  void clearAll() async {
    await ref.read(dbProvider.notifier).clearAll();
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          date2Txt(date),
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.account_box),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) {
                return const Eigenschaften();
              }),
            );
            // after storing and returning from push, read eig. again
            eigFuture = ref.read(dbProvider.notifier).readEigenschaften();
            initFuture = Future.wait([dayFuture, eigFuture]);
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () async {
              final l = await selectMonthSearch(context);
              if (l == null) return;
              final [year, month] = l;
              final missDayIdx =
                  await sendExcel(ref, year, month, eigenschaften!);
              if (missDayIdx != null) {
                int? dayDelta = deltaDays(missDayIdx);
                if (dayDelta != null) {
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  ScaffoldMessenger.of(scaffoldKey.currentContext!)
                      .showSnackBar(SnackBar(
                          content: Text(
                              "Bitte Daten vom $missDayIdx vervollständigen!")));
                  useDate(dayDelta + 65 - currDay);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearAll,
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: PageView.builder(
        onPageChanged: (value) {
          // print("xxxx onpc $value $currDay $explicitChange");
          if (!explicitChange) {
            // page reached by swiping, not by clicking <,<<,>,>>
            useDate(value - currDay);
          }
        },
        controller: pageController,
        itemCount: 2 * daysSpan,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async => await useDate(-7),
                        child: const Text("<<"),
                      ),
                      ElevatedButton(
                        onPressed: () async => await useDate(-1),
                        child: const Text("<"),
                      ),
                      ElevatedButton(
                        onPressed: () async => await useDate(tODAY),
                        child: const Text("Heute"),
                      ),
                      ElevatedButton(
                        onPressed: () async => await useDate(1),
                        child: const Text(">"),
                      ),
                      ElevatedButton(
                        onPressed: () async => await useDate(7),
                        child: const Text(">>"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                    future: initFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      eigenschaften = snapshot.data[1];
                      if (eigenschaften?[0] == "") {
                        return Container(
                            padding: const EdgeInsets.symmetric(vertical: 100),
                            child:
                                const Text("Bitte erst Namen etc. eingeben"));
                      } else {
                        return Column(
                          children: [
                            Einsatz(1, store),
                            const SizedBox(height: 20),
                            Einsatz(2, store),
                            const SizedBox(height: 20),
                            Einsatz(3, store),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
