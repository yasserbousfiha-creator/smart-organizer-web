import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal/portal_client.dart';

/// أسماء الصلوات الخمس بترتيبها اليومي، وهي نفسها أسماء الأعمدة فجدول
/// `prayers` فـ Supabase.
const List<String> kPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

class PrayerDay {
  PrayerDay({required this.date, required this.status, this.message = ''});

  final DateTime date;
  final Map<String, bool> status;
  final String message;

  bool get allDone => kPrayerNames.every((p) => status[p] == true);

  factory PrayerDay.fromRow(Map<String, dynamic> row) {
    return PrayerDay(
      date: DateTime.parse(row['prayer_date'] as String),
      status: {for (final p in kPrayerNames) p: row[p] == true},
      message: (row['message'] as String?) ?? '',
    );
  }

  factory PrayerDay.empty(DateTime date) {
    return PrayerDay(date: date, status: {for (final p in kPrayerNames) p: false});
  }
}

class PrayerStorage {
  static const table = 'prayers';

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// كيجيب صف اليوم، وكيخلق وحد فارغ إيلا ماكانش موجود بعد.
  static Future<PrayerDay> fetchToday() async {
    final today = _todayKey();
    final existing = await portalClient
        .from(table)
        .select()
        .eq('prayer_date', today)
        .maybeSingle();

    if (existing != null) {
      return PrayerDay.fromRow(existing);
    }

    final created = await portalClient
        .from(table)
        .insert({'prayer_date': today})
        .select()
        .single();
    return PrayerDay.fromRow(created);
  }

  static Future<PrayerDay> setPrayer(String prayerName, bool value) async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({prayerName: value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  static Future<PrayerDay> setMessage(String message) async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({'message': message, 'updated_at': DateTime.now().toIso8601String()})
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  /// اشتراك مباشر (Realtime) فتغييرات صف اليوم — باش الصفحة تتحدث وحدها
  /// من غير ما تحتاج refresh، حتى لو الصلاة تعلمت من جهاز آخر.
  static RealtimeChannel subscribeToday(void Function(PrayerDay day) onChange) {
    final today = _todayKey();
    return portalClient
        .channel('prayers-$today')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'prayer_date',
            value: today,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              onChange(PrayerDay.fromRow(row));
            }
          },
        )
        .subscribe();
  }
}
