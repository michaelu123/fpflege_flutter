import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/db_provider.dart';
import 'package:fpflege/utils.dart';

class Einsatz extends ConsumerStatefulWidget {
  const Einsatz(this.no, this.store, {super.key});
  final int no;
  final Function(int, String, String) store;

  @override
  ConsumerState<Einsatz> createState() => _EinsatzState();
}

class _EinsatzState extends ConsumerState<Einsatz> {
  late Map<String, TextEditingController>
      controllerMap; // Map<String, TextEditingController>>;
  late Map<String, FocusNode> focusNodeMap;

  @override
  void initState() {
    super.initState();

    controllerMap = {
      "einsatz": TextEditingController(),
      "begin": TextEditingController(),
      "end": TextEditingController(),
      // "mvv": TextEditingController(),
      "fahrzeit": TextEditingController(),
    };
    focusNodeMap = {
      "einsatz": FocusNode(),
      "begin": FocusNode(),
      "end": FocusNode(),
      // "mvv": FocusNode(),
      "fahrzeit": FocusNode(),
    };
    for (final name in focusNodeMap.keys) {
      final fn = focusNodeMap[name];
      fn!.addListener(() {
        focusEvt(name);
      });
    }
  }

  void focusEvt(name) async {
    final hasFocus = focusNodeMap[name]!.hasFocus;
    final controller = controllerMap[name]!;

    String value = controller.text;
    if (!hasFocus) {
      String newValue;
      try {
        newValue = standardize(name, value);
        if (name == "einsatz" && widget.no == 1) {
          // TODO fillinStdBegEnd(wtag2Stunden)
          await widget.store(widget.no, "begin", "08:00");
          await widget.store(widget.no, "end", "16:30");
        }
      } catch (e) {
        newValue = "";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      if (newValue != value) {
        controller.text = value = newValue;
      }
      widget.store(widget.no, name, value);
    }
  }

  @override
  void dispose() {
    for (final controller in controllerMap.values) {
      controller.dispose();
    }
    for (final focusNode in focusNodeMap.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(dbProvider);
    final fam = widget.no == 1
        ? day.fam1
        : widget.no == 2
            ? day.fam2
            : day.fam3;
    controllerMap["einsatz"]!.text = fam.einsatz;
    controllerMap["begin"]!.text = fam.begin;
    controllerMap["end"]!.text = fam.end;
    controllerMap["fahrzeit"]!.text = fam.fahrzeit;
    bool kh = fam.kh;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controllerMap["einsatz"]!,
                focusNode: focusNodeMap["einsatz"]!,
                decoration: InputDecoration(
                    labelText: '${widget.no}. Name/Ur/Kr/Fe/Üs/Fo/Su/Di/So',
                    hintText: "Pfl-Nr oder Name,Urlaub,Krank,..."),
              ),
            ),
            const Text("KH"),
            Checkbox(
              value: kh,
              onChanged: (value) {
                kh = value ?? false;
                widget.store(widget.no, "kh", kh.toString());
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: controllerMap["begin"]!,
                focusNode: focusNodeMap["begin"]!,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                    labelText: "Beginn", hintText: "hh:mm"),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: controllerMap["end"]!,
                focusNode: focusNodeMap["end"]!,
                keyboardType: TextInputType.datetime,
                decoration:
                    const InputDecoration(labelText: "Ende", hintText: "hh:mm"),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                enabled: widget.no != 3,
                controller: controllerMap["fahrzeit"]!,
                focusNode: focusNodeMap["fahrzeit"]!,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Fahrtzeit", hintText: "0,5 oder leer"),
              ),
            ),
            // SizedBox(
            //   width: 60,
            //   child: TextField(
            //     controller: controllerMap["mvv"]!,
            //     focusNode: focusNodeMap["mvv"]!,
            //     decoration: const InputDecoration(
            //         labelText: "MVV-Euro", hintText: "Kosten Fahrkarte"),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
