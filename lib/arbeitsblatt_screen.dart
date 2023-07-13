import 'package:flutter/material.dart';
import 'package:fpflege/einsatz.dart';
import 'package:fpflege/utils.dart';

class Arbeitsblatt extends StatefulWidget {
  const Arbeitsblatt({super.key});

  @override
  State<Arbeitsblatt> createState() => _ArbeitsblattState();
}

class _ArbeitsblattState extends State<Arbeitsblatt> {
  var date = DateTime.now();
  var dateShown = "";
  var dateIdx = "";

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
    dateShown = date2Txt(date); // Mo, DD.MM.YYYY
    dateIdx = date2Idx(date); // YYYY.MM.DD
    print("xxxx dateidx $dateIdx");
    setState(() {});
  }

  void store(int no, String name, String value) {
    print("xxxx store $dateIdx $no $name $value");
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
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {},
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
