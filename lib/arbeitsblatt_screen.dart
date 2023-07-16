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
  var date = DateTime.now();
  late Future<void> Function(int, String, String) store;
  late Future<void> dayFuture;
  late Future<List<Object>> eigFuture;
  late Future initFuture;
  List<Object>? eigenschaften;

  @override
  void initState() {
    super.initState();
    dayFuture = ref.read(dbProvider.notifier).load(date);
    eigFuture = ref.read(dbProvider.notifier).readEigenschaften();
    initFuture = Future.wait([dayFuture, eigFuture]);
    store = ref.read(dbProvider.notifier).store;
  }

  void useDate(int days) {
    final now = DateTime.now();
    final lb = now.add(const Duration(days: -60));
    final ub = now.add(const Duration(days: 60));
    if (days == 0) {
      date = now;
    } else {
      date = date.add(Duration(days: days));
      if (date.isBefore(lb)) date = lb;
      if (date.isAfter(ub)) date = ub;
    }
    ref.read(dbProvider.notifier).load(date);
    setState(() {});
  }

  void clearAll() async {
    await ref.read(dbProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () {
              print("xxxx send email $eigenschaften");
            },
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
                        child: const Text("Bitte erst Namen etc. eingeben"));
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
      ),
    );
  }
}
