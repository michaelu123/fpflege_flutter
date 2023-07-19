import 'package:fpflege/db_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpflege/utils.dart';

Future<String?> sendExcel(WidgetRef ref, String search) async {
  final data = await ref.read(dbProvider.notifier).loadMonthRaw(search);
  final dayIdx = checkComplete(data);
  return dayIdx;
}

String? checkComplete(List<Map<String, Object?>> data) {
  return "2023.07.19";
}
