import 'package:flutter/material.dart';
import 'package:fpflege/utils.dart';

class Einsatz extends StatefulWidget {
  const Einsatz(this.no, this.store, {super.key});
  final int no;
  final Function(int, String, String) store;

  @override
  State<Einsatz> createState() => _EinsatzState();
}

class _EinsatzState extends State<Einsatz> {
  late Map<String, TextEditingController>
      controllerMap; // Map<String, TextEditingController>>;
  late Map<String, FocusNode> focusNodeMap;
  var _kh = false;

  @override
  void initState() {
    super.initState();

    controllerMap = {
      "name": TextEditingController(),
      "begin": TextEditingController(),
      "end": TextEditingController(),
      "mvv": TextEditingController(),
      "fahrzeit": TextEditingController(),
    };
    focusNodeMap = {
      "name": FocusNode(),
      "begin": FocusNode(),
      "end": FocusNode(),
      "mvv": FocusNode(),
      "fahrzeit": FocusNode(),
    };
    for (final name in focusNodeMap.keys) {
      final fn = focusNodeMap[name];
      fn!.addListener(() {
        focusEvt(name);
      });
    }
  }

  void focusEvt(fe) {
    final hasFocus = focusNodeMap[fe]!.hasFocus;
    final controller = controllerMap[fe]!;

    String value = controller.text;
    print("xxxxxxx ${widget.no} $fe $hasFocus $value");
    if (!hasFocus) {
      final newValue = standardize(fe, value);
      if (newValue != value) {
        controller.text = value = newValue;
        widget.store(widget.no, fe, value);
      }
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
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controllerMap["name"]!,
                focusNode: focusNodeMap["name"]!,
                decoration: InputDecoration(
                    labelText: '${widget.no}. Name/Ur/Kr/Fe/Üs/Fo/Su/Di/So',
                    hintText: "Pfl-Nr oder Name,Urlaub,Krank,..."),
              ),
            ),
            const Text("KH"),
            Checkbox(
              value: _kh,
              onChanged: (value) {
                _kh = value ?? false;
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
                controller: controllerMap["fahrzeit"]!,
                focusNode: focusNodeMap["fahrzeit"]!,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Fahrtzeit", hintText: "0,5 oder leer"),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: controllerMap["mvv"]!,
                focusNode: focusNodeMap["mvv"]!,
                decoration: const InputDecoration(
                    labelText: "MVV-Euro", hintText: "Kosten Fahrkarte"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
