import 'dart:convert';

import 'package:drift/drift.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class StringMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const StringMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const {};
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}
