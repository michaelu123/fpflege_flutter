import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/db_provider.dart';
import 'package:fpflege/eigenschaften_screen.dart';
import 'package:fpflege/einsatz.dart';
import 'package:fpflege/utils.dart';

class Arbeitsblatt extends ConsumerStatefulWidget {
  const Arbeitsblatt({super.key});

  @override
  ConsumerState<Arbeitsblatt> createState() => _ArbeitsblattState();
}

class _ArbeitsblattState extends ConsumerState<Arbeitsblatt> {
  var day = DateTime.now();
  var dayShown = "";
  var dayIdx = "";
  late Future<void> dayFuture;
  late Future<void> Function(int, String, String) store;

  @override
  void initState() {
    super.initState();
    dayIdx = date2Idx(day); // YYYY.MM.DD
    dayFuture = ref.read(dbProvider.notifier).load(dayIdx);
    store = ref.read(dbProvider.notifier).store;
  }

  void useDate(int days) {
    final now = DateTime.now();
    final lb = now.add(const Duration(days: -60));
    final ub = now.add(const Duration(days: 60));
    if (days == 0) {
      day = now;
    } else {
      day = day.add(Duration(days: days));
      if (day.isBefore(lb)) day = lb;
      if (day.isAfter(ub)) day = ub;
    }
    dayShown = date2Txt(day); // Mo, DD.MM.YYYY
    dayIdx = date2Idx(day); // YYYY.MM.DD
    dayFuture = ref.read(dbProvider.notifier).load(dayIdx);
    setState(() {});
  }

  void clearAll() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          date2Txt(day),
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.account_box),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) {
                return const Eigenschaften();
              }),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearAll,
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => useDate(-7),
                    child: const Text("<<"),
                  ),
                  ElevatedButton(
                    onPressed: () => useDate(-1),
                    child: const Text("<"),
                  ),
                  ElevatedButton(
                    onPressed: () => useDate(0),
                    child: const Text("Heute"),
                  ),
                  ElevatedButton(
                    onPressed: () => useDate(1),
                    child: const Text(">"),
                  ),
                  ElevatedButton(
                    onPressed: () => useDate(7),
                    child: const Text(">>"),
                  ),
                ],
              ),
              Einsatz(1, store),
              const SizedBox(height: 20),
              Einsatz(2, store),
              const SizedBox(height: 20),
              Einsatz(3, store),
            ],
          ),
        ),
      ),
    );
  }
}
