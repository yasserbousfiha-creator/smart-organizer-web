import 'dart:convert';

import 'package:http/http.dart' as http;

import 'prayer_storage.dart';

/// Fetches daily Adhan times for Abdulrahman's city (Tetouan, Morocco) from
/// the free Aladhan API, using method 21 (Moroccan Ministry of Habous and
/// Islamic Affairs) since that matches local mosque timings.
class PrayerTimesService {
  static const _city = 'Tetouan';
  static const _country = 'Morocco';
  static const _method = 21;

  static final Map<String, Map<String, DateTime>> _cache = {};

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Returns a map of fajr/dhuhr/asr/maghrib/isha to a DateTime on [date],
  /// or null if the timings couldn't be fetched (e.g. no network).
  static Future<Map<String, DateTime>?> timingsFor(DateTime date) async {
    final key = _dateKey(date);
    final cached = _cache[key];
    if (cached != null) return cached;

    final apiDate =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timingsByCity/$apiDate'
      '?city=$_city&country=$_country&method=$_method',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final timings = (body['data'] as Map<String, dynamic>)['timings'] as Map<String, dynamic>;

      DateTime parse(String key) {
        final raw = (timings[key] as String).split(' ').first; // strip any "(CET)" suffix
        final parts = raw.split(':');
        return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
      }

      final result = {
        for (final p in kPrayerNames)
          p: parse(p[0].toUpperCase() + p.substring(1)),
      };
      _cache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }
}
