import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fpflege/arbeitsblatt_screen.dart';

final theme = ThemeData.light().copyWith(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 147, 229, 250),
    brightness: Brightness.light,
    surface: const Color.fromARGB(255, 197, 205, 213),
  ),
  scaffoldBackgroundColor: const Color.fromARGB(255, 50, 58, 60),
);

void main() {
  initializeDateFormatting('de_DE', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Arbeitsblatt',
      // theme: theme,
      home: Arbeitsblatt(),
    );
  }
}
