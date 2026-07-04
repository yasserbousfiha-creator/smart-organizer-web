import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'moon_abaya_models.dart';

class MoonAbayaStorage {
  static const _key = 'moon_abaya_items_v1';

  static Future<List<MoonAbayaItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => MoonAbayaItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<MoonAbayaItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
