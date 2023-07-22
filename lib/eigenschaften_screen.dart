import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/db_provider.dart';
import 'package:fpflege/utils.dart';

class Eigenschaften extends ConsumerStatefulWidget {
  const Eigenschaften({super.key});

  @override
  ConsumerState<Eigenschaften> createState() => _EigenschaftenState();
}

class _EigenschaftenState extends ConsumerState<Eigenschaften> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<Object>> _eigenschaftenFuture;

  String newVorname = "";
  String newNachname = "";
  String newEmail = "";
  String newMoDoStunden = ""; // String because of half hours
  String newFrStunden = "";
  var isSending = false;

  @override
  void initState() {
    super.initState();
    _eigenschaftenFuture = ref.read(dbProvider.notifier).readEigenschaften();
  }

  void _save() async {
    final state = _formKey.currentState!;
    if (!state.validate()) return;
    try {
      state.save();
      await ref.read(dbProvider.notifier).storeEigenschaften(
          newVorname, newNachname, newEmail, newMoDoStunden, newFrStunden);

      // ignore: use_build_context_synchronously
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Daten"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: _eigenschaftenFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasData) {
                List<Object>? eigenschaften = snapshot.data!;
                newVorname = eigenschaften[0] as String;
                newNachname = eigenschaften[1] as String;
                newEmail = eigenschaften[2] as String;
                newMoDoStunden = eigenschaften[3] as String;
                newFrStunden = eigenschaften[4] as String;
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: newVorname,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          label: Text('Vorname'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return "Zwischen 2 and 50 Buchstaben.";
                          }
                          return null;
                        },
                        onSaved: (v) {
                          newVorname = v!.trim();
                        },
                      ),
                      TextFormField(
                        initialValue: newNachname,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          label: Text('Nachname'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return "Zwischen 2 and 50 Buchstaben.";
                          }
                          return null;
                        },
                        onSaved: (v) {
                          newNachname = v!.trim();
                        },
                      ),
                      TextFormField(
                        initialValue: newEmail,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          label: Text(
                              'Email-Adresse des Empfängers (z.B. fpflege@die-mitterfelder.de)'),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return "Zwischen 2 and 50 Buchstaben.";
                          }
                          if (!value.contains("@")) {
                            return "Kein @ in Email-Adresse";
                          }
                          return null;
                        },
                        onSaved: (v) {
                          newEmail = v!.trim();
                        },
                      ),
                      TextFormField(
                        initialValue: newMoDoStunden,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: Text("Arbeitsstunden Mo-Do"),
                        ),
                        validator: (value) {
                          final msg = checkStunden(value);
                          return msg;
                        },
                        onSaved: (v) {
                          newMoDoStunden = v ?? "";
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        initialValue: newFrStunden,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: Text("Arbeitsstunden am Freitag"),
                        ),
                        validator: (value) {
                          final msg = checkStunden(value);
                          return msg;
                        },
                        onSaved: (v) {
                          newFrStunden = v ?? "";
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // TextButton(
                          //     onPressed: isSending
                          //         ? null
                          //         : () {
                          //             _formKey.currentState!.reset();
                          //           },
                          //     child: const Text("Löschen")),
                          ElevatedButton(
                              onPressed: isSending ? null : _save,
                              child: isSending
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text("Speichern")),
                        ],
                      )
                    ],
                  ),
                );
              } else {
                return const Text("???");
              }
            },
          ),
        ),
      ),
    );
  }
}
